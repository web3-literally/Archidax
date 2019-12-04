module Arke::Exchange
  # This class holds Rubykube Exchange logic implementation
  class Rubykube < Base

    # Takes config (hash), strategy(+Arke::Strategy+ instance)
    # * +strategy+ is setted in +super+
    # * creates @connection for RestApi
    def initialize(config)
      super

      @current_user = Member.find 3
      @current_market = Market.find config['market'].downcase
      # @connection = Faraday.new("#{config['host']}/api/v2") do |builder|
      #   # builder.response :logger
      #   builder.response :json
      #   builder.adapter :em_synchrony
      # end

      @current_user.orders.active.where(market_id: config['market'].downcase).each do |order|
        @open_orders.add_order(Arke::Order.new(@market, order.price.to_f, order.volume.to_f, order.type == "OrderAsk" ? :sell : :buy), order.id)
      end

    end

    # Ping the api
    def ping
      # @connection.get '/barong/identity/ping'
    end

    # Takes +order+ (+Arke::Order+ instance)
    # * creates +order+ via RestApi
    def create_order(order)
      # response = post(
      #   'peatio/market/orders',
      #   {
      #     market: order.market.downcase,
      #     side:   order.side.to_s,
      #     volume: order.amount,
      #     price:  order.price
      #   }
      # )

      return if order.amount < 1e-8
      od = build_order(order)

      Ordering.new(od).submit
      @open_orders.add_order(order, od.id) if od.id
      # @open_orders.add_order(order, response.env.body['id']) if response.env.status == 201 && response.env.body['id']

      # response
    end

    # Takes +order+ (+Arke::Order+ instance)
    # * cancels +order+ via RestApi
    def stop_order(id)
      # response = post(
      #   "peatio/market/orders/#{id}/cancel"
      # )
      #

      order = @current_user.orders.find id
      Ordering.new(order).cancel
      @open_orders.remove_order(id)

      # response
    end

    private

    def build_order(attrs)
      (attrs.side == :sell ? OrderAsk : OrderBid).new \
          state:         ::Order::WAIT,
          member:        @current_user,
          ask:           @current_market&.base_unit,
          bid:           @current_market&.quote_unit,
          market:        @current_market,
          ord_type:      'limit',
          price:         attrs.price,
          volume:        attrs.amount,
          origin_volume: attrs.amount
    end

    # Helper method to perform post requests
    # * takes +conn+ - faraday connection
    # * takes +path+ - request url
    # * takes +params+ - body for +POST+ request
    def post(path, params = nil)
      response = @connection.post do |req|
        req.headers = generate_headers
        req.url path
        req.body = params.to_json
      end
      Arke::Log.fatal(build_error(response)) if response.env.status != 201
      response
    end

    # Helper method, generates headers to authenticate with +api_key+
    def generate_headers
      nonce = Time.now.to_i.to_s
      {
        'X-Auth-Apikey' => @api_key,
        'X-Auth-Nonce' => nonce,
        'X-Auth-Signature' => OpenSSL::HMAC.hexdigest('SHA256', @secret, nonce + @api_key),
        'Content-Type' => 'application/json'
      }
    end
  end
end
