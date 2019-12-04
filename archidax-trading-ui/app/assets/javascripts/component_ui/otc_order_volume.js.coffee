@OtcOrderVolumeUI = flight.component ->
  flight.compose.mixin @, [OtcOrderInputMixin]

  @attributes
    precision: gon.otc_market.ask_precision
    variables:
      input: 'volume'
      known: 'price'
      output: 'total'

  @onOutput = (event, order) ->
    return if order.price.equals(0)
    volume = order.total.div order.price

    @changeOrder @value unless @validateRange(volume)
    @setInputValue @value

    order.volume = @value
    @trigger 'otc_place_order::order::updated', order
