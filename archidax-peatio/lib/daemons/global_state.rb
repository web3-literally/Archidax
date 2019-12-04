# encoding: UTF-8
# frozen_string_literal: true

require File.join(ENV.fetch("RAILS_ROOT"), "config", "environment")

require "peatio/mq/events"

$running = true
Signal.trap(:TERM) { $running = false }

while $running
  tickers = {}

  # NOTE: Turn off push notifications for disabled markets.
  Market.enabled.each do |market|
    state = Global[market.id]

    Peatio::MQ::Events.publish("public", market.id, "update", {
      asks: state.asks,
      bids: state.bids,
    })

    tickers[market.id] = market.unit_info.merge(state.ticker)
  end

  Peatio::MQ::Events.publish("public", "global", "tickers", tickers)

  tickers.clear

  otc_tickers = {}

  # NOTE: Turn off push notifications for disabled otc markets.
  OtcMarket.enabled.each do |otc_market|
    state = Global[otc_market.id]

    Peatio::MQ::Events.publish("public", otc_market.id, "otc_update", {
        otc_asks: state.otc_asks,
        otc_bids: state.otc_bids,
    })

    otc_tickers[otc_market.id] = otc_market.unit_info.merge(state.otc_ticker)
  end

  Peatio::MQ::Events.publish("public", "global", "otc_tickers", otc_tickers)

  otc_tickers.clear

  Kernel.sleep 5
end
