# encoding: UTF-8
# frozen_string_literal: true

module APIv2
  module Entities
    class OtcMarket < Base
      expose(
          :id,
          documentation: {
            type: String,
            desc: "Unique OTC market id. It's always in the form of xxxyyy,"\
                  "where xxx is the base currency code, yyy is the quote"\
                  "currency code, e.g. 'btcusd'. All available markets can"\
                  "be found at /api/v2/otc_markets."
          }
        )

        expose(
          :name,
          documentation: {
            type: String,
            desc: 'OTC Market name.'
          }
        )
    end
  end
end
