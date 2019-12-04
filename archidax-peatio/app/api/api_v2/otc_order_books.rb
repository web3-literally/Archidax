# encoding: UTF-8
# frozen_string_literal: true

module APIv2
  class OtcOrderBook < Struct.new(:asks, :bids); end

  class OtcOrderBooks < Grape::API
    helpers ::APIv2::NamedParams

    desc 'Get the OTC order book of specified market.',
      is_array: true,
      success: APIv2::Entities::OtcOrderBook
    params do
      use :otc_market
      optional :asks_limit, type: Integer, default: 20, range: 1..200, desc: 'Limit the number of returned sell otc orders. Default to 20.'
      optional :bids_limit, type: Integer, default: 20, range: 1..200, desc: 'Limit the number of returned buy otc orders. Default to 20.'
    end
    get "/otc_order_book" do
      asks = OtcOrderAsk.active.with_otc_market(params[:otc_market]).matching_rule.limit(params[:asks_limit])
      bids = OtcOrderBid.active.with_otc_market(params[:otc_market]).matching_rule.limit(params[:bids_limit])
      book = OtcOrderBook.new asks, bids
      present book, with: APIv2::Entities::OtcOrderBook
    end

    desc 'Get depth or specified OTC market. Both asks and bids are sorted from highest price to lowest.'
    params do
      use :otc_market
      optional :limit, type: Integer, default: 300, range: 1..1000, desc: 'Limit the number of returned price levels. Default to 300.'
    end
    get "/depth" do
      global = Global[params[:otc_market]]
      asks = global.otc_asks[0,params[:limit]].reverse
      bids = global.otc_bids[0,params[:limit]]
      { timestamp: Time.now.to_i, asks: asks, bids: bids }
    end
  end
end
