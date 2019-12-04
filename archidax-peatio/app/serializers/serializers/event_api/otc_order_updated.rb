# encoding: UTF-8
# frozen_string_literal: true

module Serializers
  module EventAPI
    class OtcOrderUpdated < OtcOrderEvent
      def call(otc_order)
        super.merge! \
          previous_income_amount:  previous_income_amount(otc_order),
          previous_outcome_amount: previous_outcome_amount(otc_order),
          updated_at:              otc_order.updated_at.iso8601
      end
    end
  end
end
