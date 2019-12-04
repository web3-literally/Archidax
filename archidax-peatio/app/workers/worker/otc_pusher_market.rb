# encoding: UTF-8
# frozen_string_literal: true

require "peatio/mq/events"

module Worker
  class OtcPusherMarket
    def process(payload)
      otc_trade = OtcTrade.new(payload)

      Peatio::MQ::Events.publish("private", otc_trade.ask.member.uid, "otc_trade", otc_trade.for_notify("ask"))
      Peatio::MQ::Events.publish("private", otc_trade.bid.member.uid, "otc_trade", otc_trade.for_notify("bid"))
      Peatio::MQ::Events.publish("public", otc_trade.market.id, "otc_trades", {otc_trades: [otc_trade.for_global]})
    end
  end
end
