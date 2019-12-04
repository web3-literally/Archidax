# encoding: UTF-8
# frozen_string_literal: true

module APIv2
  module Entities
    class OtcOrder < Base
      expose :id, documentation: {
        type: Integer,
        desc: 'Unique otc order id.'
      }

      expose :side, documentation: {
        type: String,
        desc: "Either 'sell' or 'buy'."
      }

      expose :price, documentation: {
        type: BigDecimal,
        desc: 'Price for each unit. e.g.'\
              "If you want to sell/buy 1 btc at 3000 usd, the price is '3000.0'"
      }

      expose :avg_price, documentation: {
        type: BigDecimal,
        desc: 'Average execution price, average of price in trades.'
      }

      expose :state, documentation: {
        type: String,
        desc: "One of 'wait', 'done', or 'cancel'."\
              "An order in 'wait' is an active order, waiting fulfillment;"\
              "a 'done' order is an order fulfilled;"\
              "'cancel' means the order has been canceled."
      }

      expose :otc_market_id, as: :otc_market, documentation: {
        type: String,
        desc: "The OTC market in which the OTC order is placed, e.g. 'btcusd'."\
              'All available OTC markets can be found at /api/v2/otc_markets.'
      }

      expose :created_at, format_with: :iso8601, documentation: {
        type: String,
        desc: 'OTC Order create time in iso8601 format.'
      }

      expose :origin_volume, as: :volume, documentation: {
        type: BigDecimal,
        desc: 'The amount user want to sell/buy.'\
              'An OTC order could be partially executed,'\
              'e.g. an OTC order sell 5 btc can be matched with a buy 3 btc OTC order,'\
              "left 2 btc to be sold; in this case the OTC order's volume would be '5.0',"\
              "its remaining_volume would be '2.0', its executed volume is '3.0'."
      }

      expose :volume, as: :remaining_volume, documentation: {
        type: BigDecimal,
        desc: "The remaining volume, see 'volume'."
      }

      expose(
        :executed_volume,
        documentation: {
          type: BigDecimal,
          desc: "The executed volume, see 'volume'."
        }
      ) do |otc_order, _options|
          otc_order.origin_volume - otc_order.volume
        end

      expose(
        :trades_count,
        documentation: {
          type: Integer,
          desc: 'Count of trades.'
        }
      )

      expose(
        :otc_trades,
        documentation: {
          type: 'APIv2::Entities::OtcTrade',
          is_array: true,
          desc: 'OTC trades wiht this order.'
        },
        if: { type: :full }
      ) do |otc_order, _options|
          APIv2::Entities::OtcTrade.represent otc_order.otc_trades, side: side
        end

      private

      def side
        @side ||= @object.type[-3, 3] == 'Ask' ? 'sell' : 'buy'
      end
    end
  end
end
