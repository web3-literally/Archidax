Rails.application.routes.draw do
  get 'trading/:market_id', to: 'markets#show'
  get 'simple-trading/:market_id', to: 'markets#trading'
  get 'otc-trading/:otc_market_id', to: 'otc_markets#show'
end
