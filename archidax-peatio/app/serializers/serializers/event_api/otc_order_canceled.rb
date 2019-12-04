# encoding: UTF-8
# frozen_string_literal: true

module Serializers
  module EventAPI
    class OtcOrderCanceled < OtcOrderEvent
      def call(otc_order)
        super.merge! \
          canceled_at: otc_order.updated_at.iso8601
      end
    end
  end
end
