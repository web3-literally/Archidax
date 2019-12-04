@OtcMyOrdersUI = flight.component ->
  flight.compose.mixin this, [OtcItemListMixin]

  @getTemplate = (otc_order) -> $(JST["templates/otc_order_active"](otc_order))
  @otcOrderHandler = (event, otc_order) ->
    return unless otc_order.otc_market == gon.otc_market.id
    switch otc_order.state
      when 'wait'
        @addOrUpdateItem otc_order
      when 'cancel'
        @removeItem otc_order.id
      when 'done'
        @removeItem otc_order.id

  @cancelOtcOrder = (event) ->
    tr = $(event.target).parents('tr')
    if confirm(otc_formatter.t('otc_place_order')['confirm_cancel'])
      $.ajax
        url:     otc_formatter.otc_market_url gon.otc_market.id, tr.data('id')
        method:  'delete'
  @after 'initialize', ->
    @on document, 'otc_order::wait::populate', @otc_populate
    @on document, 'otc_order::wait otc_order::cancel otc_order::done', @otcOrderHandler
    @on @select('tbody'), 'click', @cancelOtcOrder
