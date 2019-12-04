# encoding: UTF-8
# frozen_string_literal: true

module Serializers
  module EventAPI
    class OtcOrderEvent
      def call(otc_order)
        {
          id:                     otc_order.id,
          otc_market:                 otc_order.otc_market_id,
          type:                   type(otc_order),
          otc_trader_uid:             Member.uid(otc_order.member_id),
          income_unit:            buy?(otc_order) ? otc_order.ask : otc_order.bid,
          income_fee_type:        'relative',
          income_fee_value:       otc_order.fee.to_s('F'),
          outcome_unit:           buy?(otc_order) ? otc_order.bid : otc_order.ask,
          outcome_fee_type:       'relative',
          outcome_fee_value:      '0.0',
          initial_income_amount:  initial_income_amount(otc_order),
          current_income_amount:  current_income_amount(otc_order),
          initial_outcome_amount: initial_outcome_amount(otc_order),
          current_outcome_amount: current_outcome_amount(otc_order),
          price:                  otc_order.price.to_s('F'),
          state:                  state(otc_order),
          trades_count:           otc_order.trades_count,
          created_at:             otc_order.created_at.iso8601
        }
      end

      class << self
        def call(otc_order)
          new.call(otc_order)
        end
      end

    private
      def state(otc_order)
        case otc_order.state
          when Order::CANCEL then 'canceled'
          when Order::DONE   then 'completed'
          else 'open'
        end
      end

      def type(otc_order)
        OtcOrderBid === otc_order ? 'buy' : 'sell'
      end

      def buy?(otc_order)
        type(otc_order) == 'buy'
      end

      def sell?(otc_order)
        !buy?(otc_order)
      end

      def initial_income_amount(otc_order)
        multiplier = buy?(otc_order) ? 1.0 : otc_order.price
        amount     = otc_order.origin_volume
        (amount * multiplier).to_s('F')
      end

      def current_income_amount(otc_order)
        multiplier = buy?(otc_order) ? 1.0 : otc_order.price
        amount     = otc_order.volume
        (amount * multiplier).to_s('F')
      end

      def previous_income_amount(otc_order)
        changes    = otc_order.previous_changes
        multiplier = buy?(otc_order) ? 1.0 : otc_order.price
        amount     = changes.key?('volume') ? changes['volume'][0] : otc_order.volume
        (amount * multiplier).to_s('F')
      end

      def initial_outcome_amount(otc_order)
        attribute = buy?(otc_order) ? 'origin_locked' : 'origin_volume'
        otc_order.send(attribute).to_s('F')
      end

      def current_outcome_amount(otc_order)
        attribute = buy?(otc_order) ? 'locked' : 'volume'
        otc_order.send(attribute).to_s('F')
      end

      def previous_outcome_amount(otc_order)
        changes   = otc_order.previous_changes
        attribute = buy?(otc_order) ? 'locked' : 'volume'
        (changes.key?(attribute) ? changes[attribute][0] : otc_order.send(attribute)).to_s('F')
      end
    end
  end
end
