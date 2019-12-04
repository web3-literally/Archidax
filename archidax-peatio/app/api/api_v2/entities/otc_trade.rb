# encoding: UTF-8
# frozen_string_literal: true

module APIv2
  module Entities
    class OtcTrade < Base
      expose :id
      expose :price
      expose :volume
      expose :funds
      expose :otc_market_id, as: :otc_market
      expose :created_at, format_with: :iso8601

      expose :maker_type do |otc_trade, _options|
        otc_trade.ask_id < otc_trade.bid_id ? :sell : :buy
      end

      expose :type do |otc_trade, _options|
        # Returns market maker order type.
        otc_trade.ask_id < otc_trade.bid_id ? :sell : :buy
      end

      expose(
        :side,
        if: ->(otc_trade, options) { options[:side] || otc_trade.side },
      ) do |otc_trade, options|
        options[:side] || otc_trade.side
      end

      expose :order_id, if: ->(otc_trade, options){ options[:current_user] } do |otc_trade, options|
        if otc_trade.ask_member_id == options[:current_user].id
          otc_trade.ask_id
        elsif otc_trade.bid_member_id == options[:current_user].id
          otc_trade.bid_id
        else
          nil
        end
      end

    end
  end
end
