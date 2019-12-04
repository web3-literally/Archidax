window.GlobalData = flight.component ->

  @refreshDocumentTitle = (event, data) ->
    symbol = gon.currencies[gon.market.bid_unit].symbol
    price  = data.last
    market = [gon.market.ask_unit, gon.market.bid_unit].join("/").toUpperCase()
    title  = 'Tradeherald Exchange'

    document.title = "#{price} #{market} – #{title}"

  @refreshOtcDocumentTitle = (event, data) ->
    symbol = gon.currencies[gon.otc_market.bid_unit].symbol
    price  = data.last
    otc_market = [gon.otc_market.ask_unit, gon.otc_market.bid_unit].join("/").toUpperCase()
    title  = 'Tradeherald Exchange'

    document.title = "#{price} #{otc_market} – #{title}"

  @refreshDepth = (data) ->
    asks = []
    bids = []
    [bids_sum, asks_sum] = [0, 0]

    _.each data.asks, ([price, volume]) ->
      if asks.length == 0 || price < _.last(asks)[0]*100
        asks.push [parseFloat(price), asks_sum += parseFloat(volume)]

    _.each data.bids, ([price, volume]) ->
      if bids.length == 0 || price > _.last(bids)[0]/100
        bids.push [parseFloat(price), bids_sum += parseFloat(volume)]

    la = _.last(asks)
    lb = _.last(bids)
    if la && lb
      mid = (_.first(bids)[0] + _.first(asks)[0])/2
      offset = Math.min.apply(Math, [Math.max(mid*0.1, 1), (mid-lb[0])*0.8, (la[0]-mid)*0.8])
    else if !la? && lb
      mid = _.first(bids)[0]
      offset = Math.min.apply(Math, [Math.max(mid*0.1, 1), (mid-lb[0])*0.8])
    else if la && !lb?
      mid = _.first(asks)[0]
      offset = Math.min.apply(Math, [Math.max(mid*0.1, 1), (la[0]-mid)*0.8])

    @trigger 'market::depth::response',
      asks: asks, bids: bids, high: mid + offset, low: mid - offset

  @refreshTicker = (data) ->
    unless @.last_tickers
      for market, ticker of data
        data[market]['buy_trend'] = data[market]['sell_trend'] = data[market]['last_trend'] = true
      @.last_tickers = data

    tickers = for market, ticker of data
      buy = parseFloat(ticker.buy)
      sell = parseFloat(ticker.sell)
      last = parseFloat(ticker.last)
      last_buy = parseFloat(@.last_tickers[market].buy)
      last_sell = parseFloat(@.last_tickers[market].sell)
      last_last = parseFloat(@.last_tickers[market].last)

      if buy != last_buy
        data[market]['buy_trend'] = ticker['buy_trend'] = (buy > last_buy)
      else
        ticker['buy_trend'] = @.last_tickers[market]['buy_trend']

      if sell != last_sell
        data[market]['sell_trend'] = ticker['sell_trend'] = (sell > last_sell)
      else
        ticker['sell_trend'] = @.last_tickers[market]['sell_trend']

      if last != last_last
        data[market]['last_trend'] = ticker['last_trend'] = (last > last_last)
      else
        ticker['last_trend'] = @.last_tickers[market]['last_trend']

      if market == gon.market.id
        @trigger 'market::ticker', ticker

      market: market, data: ticker

    @trigger 'market::tickers', {tickers: tickers, raw: data}
    @.last_tickers = data

  @refreshOtcTicker = (data) ->
    unless @.last_otc_tickers
      for otc_market, otc_ticker of data
        data[otc_market]['buy_trend'] = data[otc_market]['sell_trend'] = data[otc_market]['last_trend'] = true
      @.last_otc_tickers = data

    otc_tickers = for otc_market, otc_ticker of data
      buy = parseFloat(otc_ticker.buy)
      sell = parseFloat(otc_ticker.sell)
      last = parseFloat(otc_ticker.last)
      last_buy = parseFloat(@.last_otc_tickers[otc_market].buy)
      last_sell = parseFloat(@.last_otc_tickers[otc_market].sell)
      last_last = parseFloat(@.last_otc_tickers[otc_market].last)

      if buy != last_buy
        data[otc_market]['buy_trend'] = otc_ticker['buy_trend'] = (buy > last_buy)
      else
        otc_ticker['buy_trend'] = @.last_otc_tickers[otc_market]['buy_trend']

      if sell != last_sell
        data[otc_market]['sell_trend'] = otc_ticker['sell_trend'] = (sell > last_sell)
      else
        otc_ticker['sell_trend'] = @.last_otc_tickers[otc_market]['sell_trend']

      if last != last_last
        data[otc_market]['last_trend'] = otc_ticker['last_trend'] = (last > last_last)
      else
        otc_ticker['last_trend'] = @.last_otc_tickers[otc_market]['last_trend']

      if otc_market == gon.otc_market.id
        @trigger 'otc_market::ticker', otc_ticker

      market: otc_market, data: otc_ticker

    @trigger 'otc_market::tickers', {tickers: otc_tickers, raw: data}
    @.last_otc_tickers = data

  @after 'initialize', ->
    @on document, 'market::ticker', @refreshDocumentTitle
    @on document, 'otc_market::ticker', @refreshOtcDocumentTitle

    @attr.ranger.bind 'global.tickers', (data) =>
      @refreshTicker(data)

    @attr.ranger.bind 'global.otc_tickers', (data) =>
      @refreshOtcTicker(data)

    @attr.ranger.bind "#{gon.market.id}.update", (data) =>
      gon.asks = data.asks
      gon.bids = data.bids
      @trigger 'market::order_book::update', asks: data.asks, bids: data.bids
      @refreshDepth asks: data.asks, bids: data.bids

    @attr.ranger.bind "#{gon.otc_market.id}.otc_update", (data) =>
      gon.otc_asks = data.otc_asks
      gon.otc_bids = data.otc_bids
      @trigger 'otc_market::order_book::update', otc_asks: data.otc_asks, otc_bids: data.otc_bids

    @attr.ranger.bind "#{gon.market.id}.trades", (data) =>
      @trigger 'market::trades', {trades: data.trades}
    @attr.ranger.bind "#{gon.market.id}.otc_trades", (data) =>
      @trigger 'otc_market::trades', {otc_trades: data.otc_trades}

    # Initializing at bootstrap
    if gon.ticker
      @trigger 'market::ticker', gon.ticker

    if gon.otc_ticker
      @trigger 'otc_market::ticker', gon.otc_ticker

    if gon.tickers
      @refreshTicker(gon.tickers)

    if gon.otc_tickers
      @refreshOtcTicker(gon.otc_tickers)

    if gon.asks and gon.bids
      @trigger 'market::order_book::update', asks: gon.asks, bids: gon.bids
      @refreshDepth asks: gon.asks, bids: gon.bids

    if gon.otc_asks and gon.otc_bids
      @trigger 'otc_market::order_book::update', otc_asks: gon.otc_asks, otc_bids: gon.otc_bids

    if gon.trades # is in desc order initially
      # .reverse() will modify original array! It makes gon.trades sorted
      # in asc order afterwards
      @trigger 'market::trades', trades: gon.trades.reverse()

    if gon.otc_trades # is in desc order initially
      # .reverse() will modify original array! It makes gon.trades sorted
      # in asc order afterwards
      @trigger 'otc_market::trades', otc_trades: gon.otc_trades.reverse()