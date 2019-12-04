# encoding: UTF-8
# frozen_string_literal: true

class OtcMarketConstraint
  def self.matches?(request)
    id = request.path_parameters[:otc_market_id] || request.path_parameters[:id]
    otc_market = OtcMarket.enabled.find_by_id(id)
    if otc_market
      request.path_parameters[:otc_market] = id
      request.path_parameters[:ask] = otc_market.base_unit
      request.path_parameters[:bid] = otc_market.quote_unit
    else
      false
    end
  end
end

