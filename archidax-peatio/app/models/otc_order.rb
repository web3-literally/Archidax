class OtcOrder < ActiveRecord::Base
    include BelongsToOtcMarket
    include BelongsToMember

    extend Enumerize
    enumerize :state, in: { wait: 100, done: 200, offer: 150, cancel: 0 }, scope: true

    # zealousWang todo: need to update order types, validation order_type
    # skip market type orders, they should not appear on trading-ui
    after_commit :trigger_pusher_event

    before_validation :fix_number_precision, on: :create

    validates :volume, :origin_volume, :locked, :origin_locked, presence: true
    validates :price, numericality: { greater_than: 0 }
    # zealousWang todo: need to add status: "Offer", "Reject" here.
    WAIT   = 'wait'
    DONE   = 'done'
    CANCEL = 'cancel'
    OFFER  = 'offer'

    scope :done, -> { with_state(:done) }
    scope :active, -> { with_state(:wait) }
    scope :follow, -> { with_state(:offer) }

    before_validation(on: :create) { self.fee = config.public_send("#{kind}_fee") }

    # zealousWang todo: need to update Event notify for OTC order offer
    after_commit on: :create do
      EventAPI.notify ['otc_market', otc_market_id, 'otc_order_created'].join('.'), \
        Serializers::EventAPI::OtcOrderCreated.call(self)
    end

    after_commit on: :update do
      #  zealousWang todo: need update for OTC
      event = case previous_changes.dig('state', 1)
        when 'cancel' then 'otc_order_canceled'
        when 'done'   then 'otc_order_completed'
        else 'otc_order_updated'
      end

      EventAPI.notify ['otc_market', otc_market_id, event].join('.'), \
        Serializers::EventAPI.const_get(event.camelize).call(self)
    end

    def offers
      OtcOrder.follow.where(offer_id: id)
    end

    def match_with_offer(offer_order)
      trade_price = offer_order.price
      if OtcOrderAsk === self
        trade_volume = out_amount = [offer_order.volume, volume].min
        trade_funds = income_amount = (trade_volume * trade_price).floor 8
        ask_member = member
        bid_member = offer_order.member
        myincom_account = member.ac bid
        myout_account = member.ac ask
        offerincome_account = offer_order.member.ac ask
        offerout_account = offer_order.member.ac bid
        ask_id = id
        bid_id = offer_order.id
      else
        trade_funds = out_amount = [locked, offer_order.volume * trade_price].min
        trade_volume = income_amount = (trade_funds / trade_price).floor 8
        bid_member = member
        ask_member = offer_order.member
        myincom_account = member.ac ask
        myout_account = member.ac bid
        offerincome_account = offer_order.member.ac bid
        offerout_account = offer_order.member.ac ask
        ask_id = offer_order.id
        bid_id = id
      end

      out_fee = out_amount * offer_order.fee
      income_fee = income_amount * fee
      real_out = out_amount - out_fee
      real_income = income_amount - income_fee

      ActiveRecord::Base.transaction do
        trade = OtcTrade.new(
            ask_id:        ask_id,
            ask_member_id: ask_member.id,
            bid_id:        bid_id,
            bid_member_id: bid_member.id,
            price:         trade_price,
            volume:        trade_volume,
            funds:         trade_funds,
            otc_market:    otc_market,
            trend:         trade_price >= otc_market.latest_price ? 'up' : 'down'
        )
        trade.save!

        self.volume -= trade.volume
        self.locked -= out_amount
        self.funds_received += income_amount
        self.trades_count += 1
        if self.volume.zero? || self.locked.zero?
          self.state = DONE
          unless self.locked.zero?
            myout_account.assign_attributes myout_account.attributes_after_unlock_funds!(self.locked)
            self.locked = 0
          end
        end
        self.save!

        myout_account.assign_attributes myout_account.attributes_after_unlock_and_sub_funds! out_amount
        myincom_account.assign_attributes myout_account.attributes_after_plus_funds! real_income
        myincom_account.save!
        myout_account.save!

        offer_order.volume -= trade.volume
        offer_order.locked -= income_amount
        offer_order.funds_received += out_amount
        offer_order.trades_count += 1

        if offer_order.volume.zero? || offer_order.locked.zero?
          offer_order.state = DONE
          unless offer_order.locked.zero?
            offerout_account.assign_attributes offerout_account.attributes_after_unlock_funds!(offer_order.locked)
            offer_order.locked = 0
          end
        end
        offer_order.save!

        offerout_account.assign_attributes offerout_account.attributes_after_unlock_and_sub_funds! income_amount
        offerincome_account.assign_attributes offerincome_account.attributes_after_plus_funds! real_out
        offerout_account.save!
        offerincome_account.save!
      end
    end

    # zealousWang todo: need to add after_commit on for OTC order offer, reject

    def funds_used
      origin_locked - locked
    end

    def config
      otc_market
    end

    def trigger_pusher_event
        # zealousWang todo: fix this
      Member.otc_trigger_pusher_event member_id, :otc_order, \
        id:            id,
        at:            at,
        otc_market:        otc_market_id,
        kind:          kind,
        price:         price&.to_s('F'),
        state:         state,
        volume:        volume.to_s('F'),
        origin_volume: origin_volume.to_s('F')
    end

    def kind
      self.class.name.underscore[-3, 3]
    end

    def at
      created_at.to_i
    end

    def self.head(currency)
      active.with_otc_market(currency).matching_rule.first
    end

    def to_matching_attributes
      { id:        id,
        otc_market:    otc_market_id,
        type:      type[-3, 3].downcase.to_sym,
        volume:    volume,
        price:     price,
        locked:    locked,
        timestamp: created_at.to_i }
    end

    def fix_number_precision
      self.price = config.fix_number_precision(:bid, price.to_d) if price

      if volume
        self.volume = config.fix_number_precision(:ask, volume.to_d)
        self.origin_volume = origin_volume.present? ? config.fix_number_precision(:ask, origin_volume.to_d) : volume
      end
    end

    private

    def otc_market_order_validations
      errors.add(:price, 'must not be present') if price.present?
    end
  end

# == Schema Information
# Schema version: 20190611134619
#
# Table name: otc_orders
#
#  id             :integer          not null, primary key
#  bid            :string(10)       not null
#  ask            :string(10)       not null
#  otc_market_id  :string(20)       not null
#  member_id      :integer          not null
#  offer_id       :integer
#  msg            :string(255)
#  price          :decimal(32, 16)
#  volume         :decimal(32, 16)  not null
#  origin_volume  :decimal(32, 16)  not null
#  fee            :decimal(32, 16)  default(0.0), not null
#  state          :integer          not null
#  type           :string(12)       not null
#  locked         :decimal(32, 16)  default(0.0), not null
#  origin_locked  :decimal(32, 16)  default(0.0), not null
#  funds_received :decimal(32, 16)  default(0.0)
#  trades_count   :integer          default(0), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_otc_orders_on_offer_id  (offer_id)
#
