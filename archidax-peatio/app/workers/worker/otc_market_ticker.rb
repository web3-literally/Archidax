# encoding: UTF-8
# frozen_string_literal: true

module Worker
  class OtcMarketTicker

    FRESH_OTC_TRADES = 80

    def initialize
      @otc_tickers = Hash.new { |hash, otc_market_id| initialize_otc_market_data(OtcMarket.find(otc_market_id)) }
      @otc_trades  = Hash.new { |hash, otc_market_id| initialize_otc_market_data(OtcMarket.find(otc_market_id)) }
      # NOTE: Update otc_ticker only for enabled otc markets.
      OtcMarket.enabled.each(&method(:initialize_otc_market_data))
    end

    def process(payload, metadata, delivery_info)
      otc_trade = OtcTrade.new payload
      update_ticker otc_trade
      update_latest_otc_trades otc_trade
    end

    def update_ticker(otc_trade)
      otc_ticker        = @otc_tickers[otc_trade.otc_market.id]
      otc_ticker[:low]  = get_otc_market_low otc_trade.otc_market.id, otc_trade
      otc_ticker[:high] = get_otc_market_high otc_trade.otc_market.id, otc_trade
      otc_ticker[:last] = otc_trade.price
      Rails.logger.info { otc_ticker.inspect }
      Rails.cache.write "peatio:#{otc_trade.otc_market.id}:otc_ticker", otc_ticker
    end

    def update_latest_otc_trades(otc_trade)
      otc_trades = @otc_trades[otc_trade.otc_market.id]
      otc_trades.unshift(otc_trade.for_global)
      otc_trades.pop if otc_trades.size > FRESH_OTC_TRADES

      Rails.cache.write "peatio:#{otc_trade.otc_market.id}:otc_trades", otc_trades
    end

    def initialize_otc_market_data(otc_market)
      otc_trades = OtcTrade.with_otc_market(otc_market)

      @otc_trades[otc_market.id] = otc_trades.order('id desc').limit(FRESH_OTC_TRADES).map(&:for_global)
      Rails.cache.write "peatio:#{otc_market.id}:otc_trades", @otc_trades[otc_market.id]

      low_otc_trade = initialize_otc_market_low(otc_market.id)
      high_otc_trade = initialize_otc_market_high(otc_market.id)

      @otc_tickers[otc_market.id] = {
        low:  low_otc_trade.try(:price)   || ::OtcTrade::ZERO,
        high: high_otc_trade.try(:price)  || ::OtcTrade::ZERO,
        last: otc_trades.last.try(:price) || ::OtcTrade::ZERO
      }
      Rails.cache.write "peatio:#{otc_market.id}:otc_ticker", @otc_tickers[otc_market.id]
    end

    private

    def get_otc_market_low(otc_market, otc_trade)
      low_key = "peatio:otc_#{otc_market}:h24:low"
      low = Rails.cache.read(low_key)

      if low.nil?
        otc_trade = initialize_otc_market_low(otc_market)
        low = otc_trade.price
      elsif otc_trade.price < low
        low = otc_trade.price
        write_h24_key low_key, low
      end

      low
    end

    def get_otc_market_high(otc_market, otc_trade)
      high_key = "peatio:otc_#{otc_market}:h24:high"
      high = Rails.cache.read(high_key)

      if high.nil?
        otc_trade = initialize_otc_market_high(otc_market)
        high = otc_trade.price
      elsif otc_trade.price > high
        high = otc_trade.price
        write_h24_key high_key, high
      end

      high
    end

    def initialize_otc_market_low(otc_market)
      if low_otc_trade = OtcTrade.with_otc_market(otc_market).h24.order('price asc').first
        ttl = low_otc_trade.created_at.to_i + 24.hours - Time.now.to_i
        write_h24_key "peatio:otc_#{otc_market}:h24:low", low_otc_trade.price, ttl
        low_otc_trade
      end
    end

    def initialize_otc_market_high(otc_market)
      if high_otc_trade = OtcTrade.with_otc_market(otc_market).h24.order('price desc').first
        ttl = high_otc_trade.created_at.to_i + 24.hours - Time.now.to_i
        write_h24_key "peatio:otc_#{otc_market}:h24:high", high_otc_trade.price, ttl
        high_otc_trade
      end
    end

    def write_h24_key(key, value, ttl=24.hours)
      Rails.cache.write key, value, expires_in: ttl
    end

  end
end
