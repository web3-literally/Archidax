# frozen_string_literal: true

module APIv2
  class OtcOrders < Grape::API
    helpers ::APIv2::NamedParams

    before { authenticate! }
    before { otc_trading_must_be_permitted! }

    desc 'Get your OTC orders, results is paginated.', scopes: %w[history trade],
                                                   is_array: true,
                                                   success: APIv2::Entities::OtcOrder
    params do
      use :otc_market
      optional :state, type: String,  default: 'wait', values: -> { OtcOrder.state.values }, desc: "Filter OTC order by state, default to 'wait' (active OTC orders)."
      optional :limit, type: Integer, default: 100, range: 1..1000, desc: 'Limit the number of returned OTC orders, default to 100.'
      optional :page,  type: Integer, default: 1, desc: 'Specify the page of paginated results.'
      optional :order_by, type: String, values: %w[asc desc], default: 'asc', desc: "If set, returned OTC orders will be sorted in specific order, default to 'asc'."
    end
    get '/otc_orders' do
      otc_orders = current_user.otc_orders
                           .order(order_param)
                           .with_otc_market(current_otc_market)
                           .with_state(params[:state])
                           .page(params[:page])
                           .per(params[:limit])

      present otc_orders, with: APIv2::Entities::OtcOrder
    end

    desc 'Get information of specified otc order.', scopes: %w[history trade], success: APIv2::Entities::OtcOrder
    params do
      use :otc_order_id
    end
    get '/otc_order' do
      otc_order = current_user.otc_orders.where(id: params[:id]).first
      raise OtcOrderNotFoundError, params[:id] unless otc_order

      present otc_order, with: APIv2::Entities::OtcOrder, type: :full
    end

    desc 'Create multiple sell/buy OTC orders.', scopes: %w[otc_trade],
    is_array: true,
    success: APIv2::Entities::OtcOrder
    params do
      use :otc_market
      requires :otc_orders, type: Array do
        use :otc_order
      end
    end
    post '/otc_orders/multi' do
      otc_orders = create_otc_orders params[:otc_orders]
      present otc_orders, with: APIv2::Entities::OtcOrder
    end

    desc 'Create a Sell/Buy OTC order.', scopes: %w[otc_trade], success: APIv2::Entities::OtcOrder
    params do
      use :otc_market, :otc_order
    end
    post '/otc_orders' do
      otc_order = create_otc_order params
      present otc_order, with: APIv2::Entities::OtcOrder
    end

    desc 'Cancel an otc_order.', scopes: %w[otc_trade], success: APIv2::Entities::OtcOrder
    params do
      use :otc_order_id
    end
    post '/otc_order/delete' do
      otc_order = current_user.otc_orders.find(params[:id])
      OtcOrdering.new(otc_order).cancel
      present otc_order, with: APIv2::Entities::OtcOrder
    rescue StandardError
      raise CancelOtcOrderError, $ERROR_INFO
    end

    desc 'Cancel all my otc_orders.', scopes: %w[otc_trade],
    is_array: true,
    success: APIv2::Entities::OtcOrder
    params do
      optional :side, type: String, values: %w[sell buy], desc: 'If present, only sell otc_orders (asks) or buy orders (bids) will be canncelled.'
    end
    post '/otc_orders/clear' do
      otc_orders = current_user.otc_orders.with_state(:wait)
      if params[:side].present?
        type = params[:side] == 'sell' ? 'OtcOrderAsk' : 'OtcOrderBid'
        otc_orders = otc_orders.where(type: type)
      end
      otc_orders.each { |o| OtcOrdering.new(o).cancel }
      present otc_orders, with: APIv2::Entities::OtcOrder
    rescue StandardError
      raise CancelOtcOrderError, $ERROR_INFO
    end
  end
end
