class OtcTrade < ActiveRecord::Base
    include BelongsToOtcMarket
    extend Enumerize
    ZERO = '0.0'.to_d
  
    enumerize :trend, in: { up: 1, down: 0 }
  
    belongs_to :ask, class_name: 'OtcOrderAsk', foreign_key: :ask_id, required: true
    belongs_to :bid, class_name: 'OtcOrderBid', foreign_key: :bid_id, required: true
    belongs_to :ask_member, class_name: 'Member', foreign_key: :ask_member_id, required: true
    belongs_to :bid_member, class_name: 'Member', foreign_key: :bid_member_id, required: true
  
    validates :price, :volume, :funds, numericality: { greater_than_or_equal_to: 0.to_d }
  
    scope :h24, -> { where('created_at > ?', 24.hours.ago) }
  
    attr_accessor :side
  
    after_commit on: :create do
      EventAPI.notify ['otc_market', otc_market_id, 'otc_trade_completed'].join('.'), \
        Serializers::EventAPI::OtcTradeCompleted.call(self)
    end
  
    class << self
      def latest_price(otc_market)
        with_otc_market(otc_market).order(id: :desc).select(:price).first.try(:price) || 0.to_d
      end
  
      def filter(otc_market, timestamp, from, to, limit, otc_order)
        otc_trades = with_otc_market(otc_market).order(otc_order)
        otc_trades = otc_trades.limit(limit) if limit.present?
        otc_trades = otc_trades.where('created_at <= ?', timestamp) if timestamp.present?
        otc_trades = otc_trades.where('id > ?', from) if from.present?
        otc_trades = otc_trades.where('id < ?', to) if to.present?
        otc_trades
      end
  
      def for_member(otc_market, member, options={})
        otc_trades = filter(otc_market, options[:time_to], options[:from], options[:to], options[:limit], options[:order]).where("ask_member_id = ? or bid_member_id = ?", member.id, member.id)
        otc_trades.each do |otc_trade|
            otc_trade.side = otc_trade.ask_member_id == member.id ? 'ask' : 'bid'
        end
      end
  
      def avg_h24_price(otc_market)
        with_otc_market(otc_market).h24.select(:price).average(:price).to_d
      end
    end
  
    def for_notify(kind = nil)
      { id:     id,
        kind:   kind || side,
        at:     created_at.to_i,
        price:  price.to_s  || ZERO,
        volume: volume.to_s || ZERO,
        ask_id: ask_id,
        bid_id: bid_id,
        market: otc_market.id }
    end
  
    def for_global
      { tid:    id,
        type:   trend == 'down' ? 'sell' : 'buy',
        date:   created_at.to_i,
        price:  price.to_s || ZERO,
        amount: volume.to_s || ZERO }
    end
  end
  

# == Schema Information
# Schema version: 20190524032638
#
# Table name: otc_trades
#
#  id            :integer          not null, primary key
#  price         :decimal(32, 16)  not null
#  volume        :decimal(32, 16)  not null
#  ask_id        :integer          not null
#  bid_id        :integer          not null
#  trend         :integer          not null
#  otc_market_id :string(20)       not null
#  ask_member_id :integer          not null
#  bid_member_id :integer          not null
#  funds         :decimal(32, 16)  not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_otc_trades_on_ask_id                           (ask_id)
#  index_otc_trades_on_ask_member_id_and_bid_member_id  (ask_member_id,bid_member_id)
#  index_otc_trades_on_bid_id                           (bid_id)
#  index_otc_trades_on_otc_market_id_and_created_at     (otc_market_id,created_at)
#
