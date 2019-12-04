window.OtcMarketTradesUI = flight.component ->
  flight.compose.mixin @, [NotificationMixin]

  @attributes
    tradeSelector: 'tr'
    newTradeSelector: 'tr.new'
    allSelector: 'a.all'
    mySelector: 'a.my'
    allTableSelector: 'table.otc-all-trades tbody'
    myTableSelector: 'table.otc-my-trades tbody'
    newMarketTradeContent: 'table.otc-all-trades tr.new div'
    newMyTradeContent: 'table.otc-my-trades tr.new div'
    otc_tradesLimit: 120

  @showAllOtcTrades = (event) ->
    @select('mySelector').removeClass('active')
    @select('allSelector').addClass('active')
    @select('myTableSelector').hide()
    @select('allTableSelector').show()

  @showMyOtcTrades = (event) ->
    @select('allSelector').removeClass('active')
    @select('mySelector').addClass('active')
    @select('allTableSelector').hide()
    @select('myTableSelector').show()

  @bufferOtcMarketTrades = (event, data) ->
    @otcMarketTrades = @otcMarketTrades.concat data.otc_trades

  @clearMarkers = (table) ->
    table.find('tr.new').removeClass('new')
    table.find('tr').slice(@attr.otc_tradesLimit).remove()

  @notifyMyOtcTrade = (otc_trade) ->
    otc_market = gon.otc_markets[trade.otc_market]
    message = gon.i18n.notification.new_otc_trade
      .replace(/%{kind}/g, gon.i18n[otc_trade.kind])
      .replace(/%{id}/g, otc_trade.id)
      .replace(/%{price}/g, otc_trade.price)
      .replace(/%{volume}/g, otc_trade.volume)
      .replace(/%{ask_unit}/g, otc_market.ask_unit.toUpperCase())
      .replace(/%{bid_unit}/g, otc_market.bid_unit.toUpperCase())
    @notify message

  @isMine = (otc_trade) ->
    return false if @otcMyTrades.length == 0

    for t in @otcMyTrades
      if otc_trade.tid == t.id
        return true
      if otc_trade.tid > t.id # @otcMyTrades is sorted reversely
        return false

  handleOtcMarketTrades = (event, data) ->
    for otc_trade in data.otc_trades
      @otcMarketTrades.unshift otc_trade
      otc_trade.classes = 'new'
      otc_trade.classes += ' mine' if @isMine(otc_trade)
      el = @select('allTableSelector').prepend(JST['templates/otc_market_trade'](otc_trade))

    @otcMarketTrades = @otcMarketTrades.slice(0, @attr.otc_tradesLimit)
    @select('newMarketTradeContent').slideDown('slow')

    setTimeout =>
      @clearMarkers(@select('allTableSelector'))
    , 900

  @handleMyOtcTrades = (event, data, notify=true) ->
    for otc_trade in data.otc_trades
      if otc_trade.otc_market.id == gon.otc_market.id
        @otcMyTrades.unshift otc_trade
        otc_trade.classes = 'new'

        el = @select('myTableSelector').prepend(JST['templates/otc_my_trade'](otc_trade))
        @select('allTableSelector').find("tr#market-trade-#{otc_trade.id}").addClass('mine')

      @notifyMyOtcTrade(otc_trade) if notify

    @otcMyTrades = @otcMyTrades.slice(0, @attr.otc_tradesLimit) if @otcMyTrades.length > @attr.otc_tradesLimit
    @select('newMyTradeContent').slideDown('slow')

    setTimeout =>
      @clearMarkers(@select('myTableSelector'))
    , 900

  @after 'initialize', ->
    @otcMarketTrades = []
    @otcMyTrades = []

    @on document, 'otc_trade::populate', (event, data) =>
      @handleMyOtcTrades(event, otc_trades: data.otc_trades.reverse(), false)
    @on document, 'otc_trade', (event, otc_trade) =>
      @handleMyOtcTrades(event, otc_trades: [otc_trade])

    @on document, 'otc_market::trades', handleOtcMarketTrades

    @on @select('allSelector'), 'click', @showAllOtcTrades
    @on @select('mySelector'), 'click', @showMyOtcTrades
