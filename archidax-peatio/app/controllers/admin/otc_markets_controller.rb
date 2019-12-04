# encoding: UTF-8
# frozen_string_literal: true

module Admin
    class OtcMarketsController < BaseController
      def index
        @otc_markets = OtcMarket.ordered.page(params[:page]).per(100)
      end
  
      def new
        @otc_market = OtcMarket.new
        render :show
      end
  
      def create
        @otc_market = OtcMarket.new
        @otc_market.assign_attributes(otc_market_params)
        if @otc_market.save
          redirect_to admin_otc_markets_path
        else
          flash[:alert] = @otc_market.errors.full_messages.first
          render :show
        end
      end
  
      def show
        @otc_market = OtcMarket.find(params[:id])
      end
  
      def update
        @otc_market = OtcMarket.find(params[:id])
        if @otc_market.update(otc_market_params)
          redirect_to admin_otc_markets_path
        else
          flash[:alert] = @otc_market.errors.full_messages.first
          redirect_to :back
        end
      end
  
    private
  
      def otc_market_params
        params.require(:otc_trading_pair).except(:id).permit(permitted_otc_market_attributes).tap do |params|
          boolean_otc_market_attributes.each do |param|
            next unless params.key?(param)
            params[param] = params[param].in?(['1', 'true', true])
          end
        end
      end
  
      def permitted_otc_market_attributes
        attributes = [
          :bid_unit,
          :bid_fee,
          :ask_unit,
          :ask_fee,
          :enabled,
          :max_bid,
          :min_ask,
          :min_bid_amount,
          :min_ask_amount,
          :position
        ]
  
        if @otc_market.new_record?
          attributes += [
            :bid_precision,
            :ask_precision
          ]
        end
  
        attributes
      end
  
      def boolean_otc_market_attributes
        %i[enabled]
      end
    end
  end
  