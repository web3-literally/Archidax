# encoding: UTF-8
# frozen_string_literal: true

module APIv2
  class OtcTrades < Grape::API
    helpers ::APIv2::NamedParams

    desc 'Get recent OTC trades on OTC market, each OTC trade is included only once. OTC trades are sorted in reverse creation order.',
      is_array: true,
      success: APIv2::Entities::OtcTrade
    params do
      use :otc_market, :otc_trade_filters
    end
    get "/otc_trades" do
      otc_trades = OtcTrade.filter(params[:otc_market], time_to, params[:from], params[:to], params[:limit], otc_order_param)
      present otc_trades, with: APIv2::Entities::OtcTrade
    end

    desc 'Get your executed OTC trades. OtC trades are sorted in reverse creation order.', scopes: %w(history),
      is_array: true,
      success: APIv2::Entities::OtcTrade
    params do
      use :otc_market, :otc_trade_filters
    end
    get "/otc_trades/my" do
      authenticate!
      otc_trading_must_be_permitted!

      otc_trades = OtcTrade.for_member(
        params[:otc_market], current_user,
        limit: params[:limit], time_to: time_to,
        from: params[:from], to: params[:to],
        order: order_param
      )

      present otc_trades, with: APIv2::Entities::OtcTrade, current_user: current_user
    end
  end
end
