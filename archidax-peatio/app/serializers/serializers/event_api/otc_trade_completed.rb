# encoding: UTF-8
# frozen_string_literal: true

module Serializers
  module EventAPI
    class OtcTradeCompleted
      def call(otc_trade)
        {
          id:                    otc_trade.id,
          otc_market:                otc_trade.otc_market.id,
          otc_price:                 otc_trade.price.to_s('F'),
          buyer_uid:             Member.uid(otc_trade.bid_member_id),
          buyer_income_unit:     otc_trade.otc_market.ask_unit,
          buyer_income_amount:   otc_trade.volume.to_s('F'),
          buyer_income_fee:      (otc_trade.volume * otc_trade.bid.fee).to_s('F'),
          buyer_outcome_unit:    otc_trade.otc_market.bid_unit,
          buyer_outcome_amount:  otc_trade.funds.to_s('F'),
          buyer_outcome_fee:     '0.0',
          seller_uid:            Member.uid(otc_trade.ask_member_id),
          seller_income_unit:    otc_trade.otc_market.bid_unit,
          seller_income_amount:  otc_trade.funds.to_s('F'),
          seller_income_fee:     (otc_trade.funds * otc_trade.ask.fee).to_s('F'),
          seller_outcome_unit:   otc_trade.otc_market.ask_unit,
          seller_outcome_amount: otc_trade.volume.to_s('F'),
          seller_outcome_fee:    '0.0',
          completed_at:          otc_trade.created_at.iso8601
        }
      end

      class << self
        def call(otc_trade)
          new.call(otc_trade)
        end
      end
    end
  end
end
