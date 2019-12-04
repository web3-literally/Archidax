# encoding: UTF-8
# frozen_string_literal: true

module BelongsToOtcMarket
  extend ActiveSupport::Concern

  included do
    belongs_to :otc_market, required: true
    scope :with_otc_market, -> (otc_market) { where(otc_market_id: OtcMarket === otc_market ? otc_market.id : otc_market) }
  end
end
