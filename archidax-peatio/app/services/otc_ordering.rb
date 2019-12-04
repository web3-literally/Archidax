# encoding: UTF-8
# frozen_string_literal: true

class OtcOrdering

  class CancelOtcOrderError < StandardError; end

  def initialize(otc_order_or_otc_orders)
    @otc_orders = Array(otc_order_or_otc_orders)
  end

  def broadcast(data)
    return unless @broadcast
    Rails.logger.debug { "otc orderbook broadcast: #{data.inspect}" }
    AMQPQueue.enqueue(:otc_slave_book, data, {persistent: false})
  end

  def submit
    ActiveRecord::Base.transaction { @otc_orders.each(&method(:do_submit)) }

    @otc_orders.each do |otc_order|
      broadcast(action: 'add', otc_order: otc_order.to_matching_attributes)
    end

    true
  end

  def cancel
    @otc_orders.each(&method(:do_cancel!))
  end

private

  def do_submit(otc_order)
    otc_order.fix_number_precision # number must be fixed before computing locked
    otc_order.locked = otc_order.origin_locked = otc_order.compute_locked
    otc_order.save!
    otc_order.hold_account!.lock_funds!(otc_order.locked)
  end

  def do_cancel!(otc_order)
    otc_order.with_lock do
      return unless otc_order.state == OtcOrder::WAIT
      otc_order.hold_account!.unlock_funds!(otc_order.locked)
      otc_order.update!(state: OtcOrder::CANCEL)
    end
    broadcast(action: 'remove', otc_order: otc_order.to_matching_attributes)
  end
end
