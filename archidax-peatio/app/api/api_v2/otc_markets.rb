# encoding: UTF-8
# frozen_string_literal: true

module APIv2
  class OtcMarkets < Grape::API
    desc 'Get all available otc markets.',
    is_array: true,
    success: APIv2::Entities::Market
    get '/otc_markets' do
      present OtcMarket.enabled.ordered, with: APIv2::Entities::OtcMarket
    end
  end
end
