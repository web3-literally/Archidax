@HeaderUI = flight.component ->
  @attributes
    vol: 'span.vol'
    amount: 'span.amount'
    high: 'span.high'
    low: 'span.low'
    last: 'span.last'
    change: 'span.change'
    sound: 'input[name="sound-checkbox"]'

  @refresh = (event, ticker) ->
    @select('vol').text("#{ticker.volume} #{gon.market.ask_unit.toUpperCase()}")
    @select('high').text(ticker.high)
    @select('low').text(ticker.low)
    @select('last').text(ticker.last)

    p1 = parseFloat ticker.open
    p2 = parseFloat ticker.last
    trend = formatter.trend(p1 <= p2)
    @select('change').html("<span class='#{trend}'>#{formatter.price_change(p1, p2)}%</span>")

  @refreshOtc = (event, otc_ticker) ->
    @select('vol').text("#{otc_ticker.volume} #{gon.otc_market.ask_unit.toUpperCase()}")
    @select('high').text(otc_ticker.high)
    @select('low').text(otc_ticker.low)
    @select('last').text(otc_ticker.last)

    p1 = parseFloat otc_ticker.open
    p2 = parseFloat otc_ticker.last
    trend = formatter.trend(p1 <= p2)
    @select('change').html("<span class='#{trend}'>#{formatter.price_change(p1, p2)}%</span>")

  @after 'initialize', ->
    @on document, 'market::ticker', @refresh
    @on document, 'otc_market::ticker', @refreshOtc

    if Cookies.get('sound') == undefined
      Cookies.set('sound', true, 30)
    state = Cookies.get('sound') == 'true' ? true : false

    @select('sound').bootstrapSwitch
      labelText: gon.i18n.switch.sound
      state: state
      handleWidth: 40
      labelWidth: 40
      onSwitchChange: (event, state) ->
        Cookies.set('sound', state, 30)

    $('header .dropdown-menu').click (e) ->
      e.stopPropagation()
