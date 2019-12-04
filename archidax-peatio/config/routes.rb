# encoding: UTF-8
# frozen_string_literal: true

# Explicitly require "lib/peatio.rb".
# You may be surprised why this line also sits in config/application.rb.
# The same line sits in config/application.rb to allows early access to lib/peatio.rb.
# We duplicate line in config/routes.rb since routes.rb is reloaded when code is changed.
# The implementation of ActiveSupport's require_dependency makes sense to use it only in reloadable files.
# That's why it is here.
require_dependency 'peatio'

Dir['app/models/deposits/**/*.rb'].each { |x| require_dependency x.split('/')[2..-1].join('/') }
Dir['app/models/withdraws/**/*.rb'].each { |x| require_dependency x.split('/')[2..-1].join('/') }

class ActionDispatch::Routing::Mapper
  def draw(routes_name)
    instance_eval(File.read(Rails.root.join("config/routes/#{routes_name}.rb")))
  end
end

Peatio::Application.routes.draw do

  root 'welcome#index'
  get '/marketcap' => 'welcome#marketcap'
  get '/overview' => 'welcome#overview'

  get '/signout' => 'sessions#destroy', :as => :signout
  get '/auth/failure' => 'sessions#failure', :as => :failure
  match '/auth/:provider/callback' => 'sessions#create', via: %i[get post]

  scope module: :private do
    resources :settings, only: [:index]

    resources :funds, only: [:index] do
      collection do
        post :gen_address
      end
    end

    resources 'deposits/:currency', controller: 'deposits', as: 'deposit', only: %i[ destroy ] do
      collection { post 'gen_address' }
    end

    resources 'withdraws/:currency', controller: 'withdraws', as: 'withdraw', only: %i[ create destroy ]

    get '/history/orders' => 'history#orders', as: :order_history
    get '/history/trades' => 'history#trades', as: :trade_history
    get '/history/account' => 'history#account', as: :account_history

    resources :markets, only: [:show], constraints: MarketConstraint do
      resources :orders, only: %i[ index destroy ] do
        collection do
          post :clear
        end
      end
      resources :order_bids, only: [:create] do
        collection do
          post :clear
        end
      end
      resources :order_asks, only: [:create] do
        collection do
          post :clear
        end
      end
    end

    resources :otc_orders, only: %i[ index show ] do
      member do
        post :accept
        post :reject
      end
    end

    resources :otc_markets, only: [:show], constraints: OtcMarketConstraint do
      resources :otc_orders, only: %i[ destroy ] do
        collection do
          post :clear
        end
      end
      # zealousWang todo: need to add "Accept", "Reject" for OTC orders
      resources :otc_order_bids, only: [:create] do
        collection do
          post :clear
        end
      end
      resources :otc_order_asks, only: [:create] do
        collection do
          post :clear
        end
      end
    end

  end

  get 'health/alive', to: 'public/health#alive'
  get 'health/ready', to: 'public/health#ready'

  get 'trading/:market_id', to: BlackHoleRouter.new, as: :trading
  get 'otc-trading/:otc_market_id', to: BlackHoleRouter.new, as: :otc_trading
  get 'simple-trading/:market_id', to: BlackHoleRouter.new, as: :simple_trading

  draw :admin

  get '/swagger', to: 'swagger#index'

  mount APIv2::Mount => APIv2::Mount::PREFIX
  mount ManagementAPIv1::Mount => ManagementAPIv1::Mount::PREFIX
end
