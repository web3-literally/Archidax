# encoding: UTF-8
# frozen_string_literal: true

require_dependency 'api_v2/entities/otc_order'

module APIv2
  module Entities
    class OtcOrderBook < Base
      expose :asks, using: OtcOrder
      expose :bids, using: OtcOrder
    end
  end
end
