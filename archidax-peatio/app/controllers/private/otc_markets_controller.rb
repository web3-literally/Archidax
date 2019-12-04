# encoding: UTF-8
# frozen_string_literal: true

module Private
  class OtcMarketsController < BaseController
    include Concerns::DisableOtcMarketsUI
    include CurrencyHelper

    skip_before_action :auth_member!, only: [:show]
    before_action :enabled_otc_market?
    after_action :set_default_otc_market?

    layout false

    def show
      @otc_bid = params[:bid]
      @otc_ask = params[:ask]

      @otc_market        = current_otc_market
      @otc_markets       = OtcMarket.enabled.ordered
      @otc_market_groups = @otc_markets.map(&:ask_unit).uniq

      @otc_bids   = @otc_market.otc_bids
      @otc_asks   = @otc_market.otc_asks
      @otc_trades = @otc_market.otc_trades

      # default to limit order
      @otc_order_bid = OtcOrderBid.new()
      @otc_order_ask = OtcOrderAsk.new()

      set_member_data if current_user
      gon.jbuilder
      # zealousWang todo: need to update trading_ui_variables function
      render json: trading_ui_variables
    end

    private

    def enabled_otc_market?
      redirect_to otc_trading_path(OtcMarket.enabled.ordered.first) unless current_otc_market.enabled?
    end

    def set_default_otc_market?
      cookies[:otc_market_id] = @otc_market.id
    end

    def set_member_data
      @member = current_user
      @otc_orders_wait = @member.otc_orders.includes(:otc_market).where(otc_market_id: @otc_market).with_state(:wait)
      @otc_trades_done = OtcTrade.includes(:otc_market).for_member(@otc_market.id, current_user, limit: 100, order: 'id desc')
    end

    def trading_ui_variables
      accounts = @member&.accounts&.enabled&.includes(:currency)&.map do |x|
        { id:         x.id,
          locked:     x.locked,
          amount:     x.amount,
          currency:   {
              code:     x.currency.code,
              symbol:   x.currency.symbol,
              type:     x.currency.type,
              icon_url: currency_icon_url(x.currency) } }
      end

      { current_otc_market: @otc_market.as_json,
        gon_variables:  gon.all_variables,
        otc_market_groups:  @otc_market_groups,
        currencies:     Currency.enabled.order(id: :asc).map { |c| { code: c.code, type: c.type } },
        current_member: @member,
        otc_markets:    @otc_markets.map { |m| m.as_json.merge!(otc_ticker: Global[m].otc_ticker) },
        my_accounts:    accounts,
        csrf_token:     form_authenticity_token
      }
    end

  end
end
