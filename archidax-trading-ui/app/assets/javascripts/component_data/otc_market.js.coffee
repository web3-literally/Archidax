@OtcMarketData = flight.component ->

  @checkTrend = (pre, cur) ->
    # time, open, high, low, close, volume
    [_, _, _, _, cur_close, _] = cur
    [_, _, _, _, pre_close, _] = pre
    cur_close >= pre_close # {true: up, false: down}

  @refreshUpdatedAt = ->
    @updated_at = Math.round(new Date().valueOf()/1000)

  @processTrades = ->
    $.each @otcTradesCache, (ti, trade) =>
      if trade.tid > @last_tid
        @last_tid = trade.tid
        @refreshUpdatedAt()
    @otcTradesCache = []

  @cacheOtcTrades = (event, data) ->
    @otcTradesCache = Array.prototype.concat @otcTradesCache, data.otc_trades

  @after 'initialize', ->
    @otcTradesCache = []
    @on document, 'otc_market::trades', @cacheOtcTrades
