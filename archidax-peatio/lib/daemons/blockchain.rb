# encoding: UTF-8
# frozen_string_literal: true

require File.join(ENV.fetch('RAILS_ROOT'), 'config', 'environment')

raise "Must provide blockchiankeys ex) [ 'btc-mainnet' ]" if ARGV.size == 0

running = true
Signal.trap(:TERM) { running = false }

puts "blockchian.rb args", ARGV

while running
  Blockchain.where(status: :active).where(key: ARGV).each do |bc|
    puts bc.name
    break unless running
    Rails.logger.info { "Processing #{bc.name} blocks." }

    BlockchainService[bc.key].process_blockchain

    Rails.logger.info { "Finished processing #{bc.name} blocks." }
  rescue => e
    report_exception(e)
  end
  Kernel.sleep 5
end

