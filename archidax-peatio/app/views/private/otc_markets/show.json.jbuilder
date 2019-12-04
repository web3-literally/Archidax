json.otc_asks @otc_asks
json.otc_bids @otc_bids
json.otc_trades @otc_trades
# zealousWang todo: need to check asks, bids, ...
if @member
  json.otc_my_trades @otc_trades_done.map(&:for_notify)
  json.otc_my_orders *([@otc_orders_wait] + %i[id at otc_market kind price state volume origin_volume])
end
