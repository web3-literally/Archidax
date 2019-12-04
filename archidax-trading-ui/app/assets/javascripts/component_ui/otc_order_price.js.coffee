@OtcOrderPriceUI = flight.component ->
  flight.compose.mixin @, [OtcOrderInputMixin]

  @attributes
    precision: gon.otc_market.bid_precision
    variables:
      input: 'price'
      known: 'volume'
      output: 'total'

  @getLastPrice = ->
    Number gon.otc_ticker.last

  @toggleAlert = (event) ->
    lastPrice = @getLastPrice()

    switch
      when !@value
        @trigger 'otc_place_order::price_alert::hide'
      when @value > (lastPrice * 1.1)
        @trigger 'otc_place_order::price_alert::show', {label: 'price_high'}
      when @value < (lastPrice * 0.9)
        @trigger 'otc_place_order::price_alert::show', {label: 'price_low'}
      else
        @trigger 'otc_place_order::price_alert::hide'

  @onOutput = (event, order) ->
    price = order.total.div order.volume
    @$node.val price

  @after 'initialize', ->
    @on 'focusout', @toggleAlert
