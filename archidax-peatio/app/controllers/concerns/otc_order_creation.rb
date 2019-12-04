# encoding: UTF-8
# frozen_string_literal: true

module Concerns
  module OtcOrderCreation
    extend ActiveSupport::Concern

    def otc_order_params(otc_order)
      params[otc_order][:bid] = Currency.enabled.find(params[:bid])&.id
      params[otc_order][:ask] = Currency.enabled.find(params[:ask])&.id
      params[otc_order][:state] = OtcOrder::WAIT unless params[otc_order][:state]
      params[otc_order][:otc_market_id] = params[:otc_market]
      params[otc_order][:member_id] = current_user.id
      params[otc_order][:volume] = params[otc_order][:origin_volume]
      params.require(otc_order).permit(
        :bid, :ask, :otc_market_id, :price,
        :state, :origin_volume, :volume, :member_id, :offer_id, :msg)
    end

    def otc_order_submit
      begin
        OtcOrdering.new(@otc_order).submit
        render status: 200, json: success_result
      rescue => e
        Rails.logger.error { "Member id=#{current_user.id} failed to submit otc_order." }
        Rails.logger.debug { params.inspect }
        report_exception(e)
        render status: 500, json: error_result(@otc_order.errors)
      end
    end

    def success_result
      Jbuilder.encode do |json|
        json.result true
        json.message I18n.t("private.otc_markets.show.success")
      end
    end

    def error_result(args)
      Jbuilder.encode do |json|
        json.result false
        json.message I18n.t("private.otc_markets.show.error")
        json.errors args
      end
    end
  end
end
