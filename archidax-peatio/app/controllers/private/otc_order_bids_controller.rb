# encoding: UTF-8
# frozen_string_literal: true

module Private
    class OtcOrderBidsController < BaseController
      include Concerns::OtcOrderCreation
  
      def create
        @otc_order = OtcOrderBid.new(otc_order_params(:otc_order_bid))
        otc_order_submit
      end
  
      def clear
        @otc_orders = OtcOrderBid.where(member_id: current_user.id).with_state(:wait).with_otc_market(current_otc_market)
        OtcOrdering.new(@otc_orders).cancel
        render status: 200, nothing: true
      end

#   zealousWang todo: add Accept OTC ask function
      def accept
        # update OTC order statuses
        # update Accounts balances
        # Create new OTC trade
        # enqueue to AMQPQueue (otc_slave_book)

      end

#   zealousWang todo: add Reject OTC ask function
      def reject
        # update OTC order statuses
        # update Accounts balances
        # Create new OTC trade
        # enqueue to AMQPQueue (otc_slave_book)
      end
  
    end
  end
  