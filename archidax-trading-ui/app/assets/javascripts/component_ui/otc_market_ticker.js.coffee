window.OtcMarketTickerUI = flight.component ->
  @attributes
    askSelector: '.ask .price'
    bidSelector: '.bid .price'
    lastSelector: '.last .price'
    priceSelector: '.price'

  @updatePrice = (selector, price, trend) ->
    selector.removeClass('text-up').removeClass('text-down').addClass(otc_formatter.trend(trend))
    selector.html(otc_formatter.fixBid(price))

  @refresh = (event, otc_ticker) ->
    @updatePrice @select('askSelector'),  otc_ticker.sell, otc_ticker.sell_trend
    @updatePrice @select('bidSelector'),  otc_ticker.buy,  otc_ticker.buy_trend
    @updatePrice @select('lastSelector'), otc_ticker.last, otc_ticker.last_trend

  @after 'initialize', ->
    @on document, 'otc_market::ticker', @refresh
