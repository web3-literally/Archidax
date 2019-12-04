@OtcPlaceOrderUI = flight.component ->
  @attributes
    formSel: 'form'
    successSel: '.status-success'
    infoSel: '.status-info'
    dangerSel: '.status-danger'
    priceAlertSel: '.hint-price-disadvantage'
    positionsLabelSel: '.hint-positions'

    priceSel: 'input[id$=price]'
    volumeSel: 'input[id$=volume]'
    totalSel: 'input[id$=total]'

    currentBalanceSel: 'span.current-balance'
    submitButton: ':submit'

  @panelType = ->
    switch @$node.attr('id')
      when 'otc_bid_entry' then 'bid'
      when 'otc_ask_entry' then 'ask'

  @cleanMsg = ->
    @select('successSel').text('')
    @select('infoSel').text('')
    @select('dangerSel').text('')

  @resetForm = (event) ->
    @trigger 'otc_place_order::reset::price'
    @trigger 'otc_place_order::reset::volume'
    @trigger 'otc_place_order::reset::total'
    @priceAlertHide()

  @disableSubmit = ->
    @select('submitButton').addClass('disabled').attr('disabled', 'disabled')

  @enableSubmit = ->
    @select('submitButton').removeClass('disabled').removeAttr('disabled')

  @confirmDialogMsg = ->
    confirmType = @select('submitButton').text()
    price = @select('priceSel').val()
    volume = @select('volumeSel').val()
    sum = @select('totalSel').val()
    """
    #{gon.i18n.otc_place_order.confirm_submit} "#{confirmType}"?

    #{gon.i18n.otc_place_order.price}: #{price}
    #{gon.i18n.otc_place_order.volume}: #{volume}
    #{gon.i18n.otc_place_order.sum}: #{sum}
    """

  @beforeSend = (event, jqXHR) ->
    if true #confirm(@confirmDialogMsg())
      @disableSubmit()
    else
      jqXHR.abort()

  @handleSuccess = (event, data) ->
    @cleanMsg()
    @select('successSel').append(JST["templates/hint_order_success"]({msg: data.message})).show()
    @resetForm(event)
    window.sfx_success()
    @enableSubmit()

  @handleError = (event, data) ->
    @cleanMsg()
    ef_class = 'shake shake-constant hover-stop'
    json = JSON.parse(data.responseText)
    @select('dangerSel').append(JST["templates/hint_order_warning"]({msg: json.message})).show()
      .addClass(ef_class).wait(500).removeClass(ef_class)
    window.sfx_warning()
    @enableSubmit()

  @getBalance = ->
    BigNumber( @select('currentBalanceSel').data('balance') )

  @getLastPrice = ->
    BigNumber(gon.otc_ticker.last)

  @allIn = (event)->
    switch @panelType()
      when 'ask'
        @trigger 'otc_place_order::input::price', {price: @getLastPrice()}
        @trigger 'otc_place_order::input::volume', {volume: @getBalance()}
      when 'bid'
        @trigger 'otc_place_order::input::price', {price: @getLastPrice()}
        @trigger 'otc_place_order::input::total', {total: @getBalance()}

  @refreshBalance = (event, data) ->
    type = @panelType()
    currency = gon.otc_market[type + '_unit']
    balance = gon.accounts[currency]?.balance || 0

    @select('currentBalanceSel').data('balance', balance)
    @select('currentBalanceSel').text(otc_formatter.fix(type, balance))

    @trigger 'otc_place_order::balance::change', balance: BigNumber(balance)
    @trigger "otc_place_order::max::#{@usedInput}", max: BigNumber(balance)

  @updateAvailable = (event, order) ->
    type = @panelType()
    node = @select('currentBalanceSel')

    order[@usedInput] = 0 unless order[@usedInput]
    available = otc_formatter.fix type, @getBalance().minus(order[@usedInput])

    if BigNumber(available).equals(0)
      @select('positionsLabelSel').hide().text(gon.i18n.otc_place_order["full_#{type}"]).fadeIn()
    else
      @select('positionsLabelSel').fadeOut().text('')
    node.text(available)

  @priceAlertHide = (event) ->
    @select('priceAlertSel').fadeOut ->
      $(@).text('')

  @priceAlertShow = (event, data) ->
    @select('priceAlertSel')
      .hide().text(gon.i18n.otc_place_order[data.label]).fadeIn()

  @clear = (e) ->
    @resetForm(e)
    @trigger 'otc_place_order::focus::price'

  @after 'initialize', ->
    type = @panelType()

    if type == 'ask'
      @usedInput = 'volume'
    else
      @usedInput = 'total'

    OtcPlaceOrderData.attachTo @$node
    OtcOrderPriceUI.attachTo   @select('priceSel'),  form: @$node, type: type
    OtcOrderVolumeUI.attachTo  @select('volumeSel'), form: @$node, type: type
    OtcOrderTotalUI.attachTo   @select('totalSel'),  form: @$node, type: type

    @on 'otc_place_order::price_alert::hide', @priceAlertHide
    @on 'otc_place_order::price_alert::show', @priceAlertShow
    @on 'otc_place_order::order::updated', @updateAvailable
    @on 'otc_place_order::clear', @clear

    @on document, 'account::update', @refreshBalance

    @on @select('formSel'), 'ajax:beforeSend', @beforeSend
    @on @select('formSel'), 'ajax:success', @handleSuccess
    @on @select('formSel'), 'ajax:error', @handleError

    @on @select('currentBalanceSel'), 'click', @allIn
