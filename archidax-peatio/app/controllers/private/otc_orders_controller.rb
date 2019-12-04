# encoding: UTF-8
# frozen_string_literal: true

module Private
    class OtcOrdersController < BaseController
  
      def destroy
        ActiveRecord::Base.transaction do
          otc_order = current_user.otc_orders.find(params[:id])
          otc_ordering = OtcOrdering.new(otc_order)
  
          if otc_ordering.cancel
            render status: 200, nothing: true
          else
            render status: 500, nothing: true
          end
        end
      end
  
      def clear
        @otc_orders = current_user.otc_orders.with_otc_market(current_otc_market).with_state(:wait)
        OtcOrdering.new(@otc_orders).cancel
        render status: 200, nothing: true
      end

      def index
        @otc_orders = current_user.otc_orders.with_state(:wait)
      end

      def show
        @otc_order = current_user.otc_orders.find params[:id]
        @otc_offers = @otc_order.offers
      end

      def accept
        @otc_order = current_user.otc_orders.find params[:id]
        @otc_offer = @otc_order.offers.find params[:offer_id]
        @otc_order.match_with_offer(@otc_offer)
        return redirect_to otc_orders_path
      end

      def reject
        @otc_order = current_user.otc_orders.find params[:id]
        @otc_offer = @otc_order.offers.find params[:offer_id]
        OtcOrdering.new(@otc_offer).cancel
        return redirect_to otc_orders_path
      end

    end
  end
  