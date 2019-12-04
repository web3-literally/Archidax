# encoding: UTF-8
# frozen_string_literal: true

module Matching
  class OtcPriceLevel

    attr :otc_price, :otc_orders

    def initialize(otc_price)
      @otc_price  = otc_price
      @otc_orders = []
    end

    def top
      @otc_orders.first
    end

    def empty?
      @otc_orders.empty?
    end

    def add(otc_order)
      unless find(otc_order.id)
        @otc_orders << otc_order
      end
    end

    def remove(otc_order)
      @otc_orders.delete_if { |o| o.id == otc_order.id }
    end

    def find(id)
      @otc_orders.find { |o| o.id == id }
    end
  end
end
