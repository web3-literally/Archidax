@OtcOrderBookUI = flight.component ->
  @attributes
    bookLimit: 30
    askBookSel: 'table.asks'
    bidBookSel: 'table.bids'
    seperatorSelector: 'table.seperator'
    fade_toggle_depth: '#fade_toggle_depth'

  @update = (event, data) ->
    @updateOtcOrders(@select('bidBookSel'), _.first(data.otc_bids, @.attr.bookLimit), 'bid')
    @updateOtcOrders(@select('askBookSel'), _.first(data.otc_asks, @.attr.bookLimit), 'ask')

  @appendRow = (book, template, data) ->
    data.classes = 'new'
    book.append template(data)

  @insertRow = (book, row, template, data) ->
    data.classes = 'new'
    row.before template(data)

  @updateRow = (row, otc_, index, v1, v2) ->
    row.data('otc_', index)
    return if v1.equals(v2)

    if v2.greaterThan(v1)
      row.addClass('text-up')
    else
      row.addClass('text-down')

    row.data('volume', otc_[1])
    row.find('td.volume').html(otc_formatter.mask_fixed_volume(otc_[1]))
    row.find('td.amount').html(otc_formatter.amount(otc_[1], otc_[0]))

  @mergeUpdate = (bid_or_ask, book, otc_orders, template) ->
    rows = book.find('tr')

    i = j = 0
    while(true)
      row = rows[i]
      otc_order = otc_orders[j]
      $row = $(row)

      if row && otc_order
        p1 = new BigNumber($row.data('price'))
        v1 = new BigNumber($row.data('volume'))
        p2 = new BigNumber(otc_order[0])
        v2 = new BigNumber(otc_order[1])
        if (bid_or_ask == 'ask' && p2.lessThan(p1)) || (bid_or_ask == 'bid' && p2.greaterThan(p1))
          @insertRow(book, $row, template,
            price: otc_order[0], volume: otc_order[1], index: j)
          j += 1
        else if p1.equals(p2)
          @updateRow($row, otc_order, j, v1, v2)
          i += 1
          j += 1
        else
          $row.addClass 'obsolete'
          i += 1
      else if row
        $row.addClass 'obsolete'
        i += 1
      else if otc_order
        @appendRow(book, template,
          price: otc_order[0], volume: otc_order[1], index: j, id: otc_order[2])
        j += 1
      else
        break

  @clearMarkers = (book) ->
    book.find('tr.new').removeClass('new')
    book.find('tr.text-up').removeClass('text-up')
    book.find('tr.text-down').removeClass('text-down')

    obsolete = book.find('tr.obsolete')
    obsolete_divs = book.find('tr.obsolete div')
    obsolete_divs.slideUp 'slow', ->
      obsolete.remove()

  @updateOtcOrders = (table, otc_orders, bid_or_ask) ->
    book = @select("#{bid_or_ask}BookSel")
    @mergeUpdate bid_or_ask, book, otc_orders, JST["templates/otc_order_book_#{bid_or_ask}"]

    book.find("tr.new div").slideDown('slow')
    setTimeout =>
      @clearMarkers(@select("#{bid_or_ask}BookSel"))
    , 900

  @computeDeep = (event, otc_orders) ->
    index      = Number $(event.currentTarget).data('order')
    otc_orders     = _.take(otc_orders, index + 1)

    volume_fun = (memo, num) -> memo.plus(BigNumber(num[1]))
    volume     = _.reduce(otc_orders, volume_fun, BigNumber(0))
    price      = BigNumber(_.last(otc_orders)[0])
    origVolume = _.last(otc_orders)[1]

    {price: price, volume: volume, origVolume: origVolume}

  @placeOtcOrder = (target, data) ->
      @trigger target, 'otc_place_order::input::price', data
      @trigger target, 'otc_place_order::input::volume', data

  @after 'initialize', ->
    @on document, 'otc_market::order_book::update', @update

    @on @select('fade_toggle_depth'), 'click', =>
      @trigger 'otc_market::depth::fade_toggle'

    $('.asks').on 'click', 'tr', (e) =>
      order_id = $(e.target).closest('tr').data('order-id')
      price = $(e.target).closest('tr').data('price')
      volume = $(e.target).closest('tr').data('volume')
      $('#otc_bid_modal_price').val(price)
      $('#otc_bid_modal_volume').val(volume)
      $('#otc_bid_modal_total').val( BigNumber(price).times(volume))
      $('#otc_bid_modal_offer_id').val(order_id)

      i = $(e.target).closest('tr').data('order')
      @placeOtcOrder $('#otc_bid_entry'), _.extend(@computeDeep(e, gon.otc_asks), type: 'ask')
      @placeOtcOrder $('#otc_ask_entry'), {price: BigNumber(gon.otc_asks[i][0]), volume: BigNumber(gon.otc_asks[i][1])}

      $('#otc_offer_dialog_bid').modal()

    $('.bids').on 'click', 'tr', (e) =>
      order_id = $(e.target).closest('tr').data('order-id')
      price = $(e.target).closest('tr').data('price')
      volume = $(e.target).closest('tr').data('volume')
      $('#otc_ask_modal_price').val(price)
      $('#otc_ask_modal_volume').val(volume)
      $('#otc_ask_modal_total').val( BigNumber(price).times(volume))
      $('#otc_ask_modal_offer_id').val(order_id)

      i = $(e.target).closest('tr').data('order')
      @placeOtcOrder $('#otc_ask_entry'), _.extend(@computeDeep(e, gon.otc_bids), type: 'bid')
      @placeOtcOrder $('#otc_bid_entry'), {price: BigNumber(gon.otc_bids[i][0]), volume: BigNumber(gon.otc_bids[i][1])}

      $('#otc_offer_dialog_ask').modal()
