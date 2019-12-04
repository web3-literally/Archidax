# encoding: UTF-8
# frozen_string_literal: true

module Worker
  class OtcSlaveBook

    def initialize(run_cache_thread=true)
      if run_cache_thread
        cache_thread = Thread.new do
          loop do
            sleep 3
            otc_cache_book
          end
        end
      end
    end

    def process(payload, metadata, delivery_info)
      @payload = Hashie::Mash.new payload

      case @payload.action
      when 'new'
        otc_cache_book
      when 'add'
        otc_cache_book
      when 'update'
        otc_cache_book
      when 'remove'
        otc_cache_book
      else
        raise ArgumentError, "Unknown action: #{@payload.action}"
      end
    rescue
      Rails.logger.error { "Failed to process payload: #{$!}" }
      Rails.logger.error { $!.backtrace.join("\n") }
    end

    def otc_cache_book
      OtcMarket.ids.each do |otc_market_id|
        Rails.cache.write "peatio:#{otc_market_id}:depth:otc_asks", get_depth(otc_market_id, :ask)
        Rails.cache.write "peatio:#{otc_market_id}:depth:otc_bids", get_depth(otc_market_id, :bid)
        Rails.logger.debug { "OtcSlaveBook (#{otc_market_id}) updated" }
      end
    rescue
      Rails.logger.error { "Failed to cache otc_book: #{$!}" }
      Rails.logger.error { $!.backtrace.join("\n") }
    end

    def get_depth(otc_market_id, side)
      # zealousWang todo: get account name for OTC orders and insert that.
      otc_orders = OtcOrder.select('*')
                       .joins("Left JOIN members ON otc_orders.member_id = members.id")
                       .where(otc_market_id: otc_market_id, state: 'wait', type: "OtcOrder#{side}")
                       .order(:price)
      ods = otc_orders.pluck(:price, :volume, :id, :name)
      if side == :bid
        ods.reverse
      else
        ods
      end

    end
  end
end
