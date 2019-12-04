# encoding: UTF-8
# frozen_string_literal: true

require_relative 'constants'

module Matching
  class OtcOrderBook

    attr :side

    def initialize(otc_market, side, options={})
      @otc_market = otc_market
      @side = side.to_sym
      @otc_orders = RBTree.new

      @broadcast = options.has_key?(:broadcast) ? options[:broadcast] : true
      broadcast(action: 'new', otc_market: @otc_market, side: @side)

    end
    
    def find(otc_order)
      @otc_orders[otc_order.price].find(otc_order.id)
    end

    def add(otc_order)
      raise InvalidOtcOrderError, "volume is zero" if otc_order.volume <= ZERO

      case otc_order
      when OtcOrder
        @otc_orders[otc_order.price] ||= OtcPriceLevel.new(otc_order.price)
        @otc_orders[otc_order.price].add otc_order
      else
        raise ArgumentError, "Unknown otc_order type"
      end

      broadcast(action: 'add', otc_order: otc_order.attributes)
    end

    def remove(otc_order)
      case otc_order
      when OtcOrder
        remove_otc_order(otc_order)
      else
        raise ArgumentError, "Unknown otc_order type"
      end
    end

    def otc_orders
      orders = {}
      @otc_orders.keys.each {|k| orders[k] = @otc_orders[k].orders }
      orders
    end

    private

    def remove_otc_order(otc_order)
      otc_price_level = @otc_orders[otc_order.price]
      return unless otc_price_level

      otc_order = otc_price_level.find otc_order.id # so we can return fresh otc_order
      return unless otc_order

      otc_price_level.remove otc_order
      @otc_orders.delete(otc_order.price) if otc_price_level.empty?

      broadcast(action: 'remove', otc_order: otc_order.attributes)
      otc_order
    end

    def broadcast(data)
      return unless @broadcast
      Rails.logger.debug { "otc orderbook broadcast: #{data.inspect}" }
      AMQPQueue.enqueue(:otc_slave_book, data, {persistent: false})
    end

  end
end
