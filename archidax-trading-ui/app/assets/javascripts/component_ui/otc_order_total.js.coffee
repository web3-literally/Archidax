@OtcOrderTotalUI = flight.component ->
  flight.compose.mixin @, [OtcOrderInputMixin]

  @attributes
    precision: gon.otc_market.bid_precision
    variables:
      input: 'total'
      known: 'price'
      output: 'volume'

  @onOutput = (event, order) ->
    total = order.price.times order.volume

    @changeOrder @value unless @validateRange(total)
    @setInputValue @value

    order.total = @value
    @trigger 'otc_place_order::order::updated', order
