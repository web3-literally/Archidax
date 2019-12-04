#= require es5-shim.min
#= require es5-sham.min

#= require jquery
#= require jquery_ujs
#= require jquery.mousewheel
#= require jquery-timing.min
#= require jquery.nicescroll.min
#
#= require bootstrap
#= require bootstrap-switch.min
#
#= require moment
#= require bignumber
#= require underscore
#= require cookies.min
#= require flight.min

#= require ./lib/sfx
#= require ./lib/notifier
#= require ./lib/ranger_events_dispatcher
#= require ./lib/ranger_connection


#= require highstock
#= require_tree ./highcharts/

#= require_tree ./helpers
#= require_tree ./component_mixin
#= require_tree ./component_data
#= require_tree ./component_ui
#= require_tree ./templates

#= require_self

$ ->
  window.notifier = new Notifier()

  BigNumber.config(ERRORS: false)

  HeaderUI.attachTo('.crypt-gross-market-cap')
  AccountSummaryUI.attachTo('#balance')

  FloatUI.attachTo('.float')
  KeyBindUI.attachTo(document)
  # AutoWindowUI.attachTo(window)

  PlaceOrderUI.attachTo('#bid_entry')
  PlaceOrderUI.attachTo('#ask_entry')
  OrderBookUI.attachTo('#active-orders')
  DepthUI.attachTo('#depths_wrapper')
  MyOrdersUI.attachTo('#my-orders')
  MarketTickerUI.attachTo('#ticker')
  MarketSwitchUI.attachTo('#market_list_container')
  MarketTradesUI.attachTo('#market_trades_container')

  # assign to my OTC market
  OtcPlaceOrderUI.attachTo('#otc_bid_entry')
  OtcPlaceOrderUI.attachTo('#otc_ask_entry')
  OtcOrderBookUI.attachTo('#otc-active-orders')
  OtcMyOrdersUI.attachTo('#otc-my-orders')
  OtcMarketTradesUI.attachTo('#otc_market_trades_container')

  OtcMarketData.attachTo(document)
  MarketData.attachTo(document)
  GlobalData.attachTo(document, {ranger: window.ranger})
  MemberData.attachTo(document, {ranger: window.ranger}) if gon.accounts

  CandlestickUI.attachTo('#candlestick')
  SwitchUI.attachTo('#range_switch, #indicator_switch, #main_indicator_switch, #type_switch')

  $('.panel-body-content').niceScroll
    autohidemode: true
    cursorborder: "none"

  $('#market_list_container .crypt-tab-content').niceScroll
    autohidemode: true
    cursorborder: "none"

  $('#market_trades_container #history').niceScroll
    autohidemode: true
    cursorborder: "none"

  $('#otc_market_trades_container #history').niceScroll
    autohidemode: true
    cursorborder: "none"

  $('#balance').niceScroll
    autohidemode: true
    cursorborder: "none"
