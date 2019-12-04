@OtcPlaceOrderData = flight.component ->

  @onInput = (event, data) ->
    {input: @input, known: @known, output: @output} = data.variables
    @order[@input] = data.value

    return unless @order[@input] && @order[@known]
    @trigger "otc_place_order::output::#{@output}", @order

  @onReset = (event, data) ->
    {input: @input, known: @known, output: @output} = data.variables
    @order[@input] = @order[@output] = null

    @trigger "otc_place_order::reset::#{@output}"
    @trigger "otc_place_order::order::updated", @order

  @after 'initialize', ->
    @order = {price: null, volume: null, total: null}

    @on 'otc_place_order::input', @onInput
    @on 'otc_place_order::reset', @onReset
