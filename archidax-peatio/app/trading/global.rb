# encoding: UTF-8
# frozen_string_literal: true

class Global
  ZERO = '0.0'.to_d
  NOTHING_ARRAY = YAML::dump([])
  LIMIT = 80

  def initialize(market_id)
    @market_id = market_id
  end

  attr_accessor :market_id

  # zealousWang: todo: need to update for OTC market
  def self.[](market)
    if market.is_a? Market
      self.new(market.id)
    else
      self.new(market.to_s)
    end
  end

  def key(key, interval = 5)
    "peatio:#{@market_id}:#{key}:#{time_key(interval)}"
  end

  def time_key(interval)
    seconds = Time.now.to_i
    seconds - (seconds % interval)
  end

  def asks
    Rails.cache.read("peatio:#{market_id}:depth:asks") || []
  end

  def bids
    Rails.cache.read("peatio:#{market_id}:depth:bids") || []
  end

  # zealousWang todo: check this will  be used
  def otc_asks
    Rails.cache.read("peatio:#{market_id}:depth:otc_asks") || []
  end

  def otc_bids
    Rails.cache.read("peatio:#{market_id}:depth:otc_bids") || []
  end

  def default_ticker
    {low: ZERO, high: ZERO, last: ZERO, volume: ZERO}
  end

  def ticker
    ticker = Rails.cache.read("peatio:#{market_id}:ticker") || default_ticker
    open = Rails.cache.read("peatio:#{market_id}:ticker:open") || ticker[:last]
    best_buy_price = bids.first && bids.first[0] || ZERO
    best_sell_price = asks.first && asks.first[0] || ZERO
    avg_price = Trade.avg_h24_price(market_id)
    price_change_percent = change_ratio(open, ticker[:last])

    ticker.merge(
        at: at,
        open: open,
        volume: h24_volume,
        sell: best_sell_price,
        buy: best_buy_price,
        avg_price: avg_price,
        price_change_percent: price_change_percent
    )
  end

  # zealousWang todo: check this will  be used
  def otc_ticker
    otc_ticker = Rails.cache.read("peatio:#{market_id}:otc_ticker") || default_ticker
    open = Rails.cache.read("peatio:#{market_id}:otc_ticker:open") || otc_ticker[:last]
    best_buy_price = otc_bids.first && otc_bids.first[0] || ZERO
    best_sell_price = otc_asks.first && otc_asks.first[0] || ZERO
    avg_price = OtcTrade.avg_h24_price(market_id)
    price_change_percent = change_ratio(open, otc_ticker[:last])

    otc_ticker.merge(
        at: at,
        open: open,
        volume: h24_volume,
        sell: best_sell_price,
        buy: best_buy_price,
        avg_price: avg_price,
        price_change_percent: price_change_percent
    )
  end

  def change_ratio(open, last)
    percent = open.zero? ? 0 : (last - open) / open * 100

    # Prepend sign. Show two digits after the decimal point. Append '%'.
    "#{'%+.2f' % percent}%"
  end

  # zealousWang todo: check this needs to be updated,
  # because OTC trades will be calculated.
  def h24_volume
    Rails.cache.fetch key('h24_volume', 5), expires_in: 24.hours do
      Trade.where(market_id: market_id).h24.sum(:volume) || ZERO
    end
  end

  def otc_h24_volume
    Rails.cache.fetch key('otc_h24_volume', 5), expires_in: 24.hours do
      OtcTrade.where(otc_market_id: market_id).h24.sum(:volume) || ZERO
    end
  end

  def trades
    Rails.cache.read("peatio:#{market_id}:trades") || []
  end

  def otc_trades
    Rails.cache.read("peatio:#{market_id}:otc_trades") || []
  end

  def at
    @at ||= DateTime.now.to_i
  end
end
