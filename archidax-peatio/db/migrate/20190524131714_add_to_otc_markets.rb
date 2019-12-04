class AddToOtcMarkets < ActiveRecord::Migration
  def change
    add_column :otc_markets, :max_bid, :decimal, precision: 17, scale: 16, after: :bid_fee
    add_column :otc_markets, :min_ask, :decimal, null: false, default: 0, precision: 17, scale: 16, after: :max_bid
    add_column :otc_markets, :min_bid_amount, :decimal, null: false, default: 0, precision: 32, scale: 16, after: :min_ask
    add_column :otc_markets, :min_ask_amount, :decimal, null: false, default: 0, precision: 32, scale: 16, after: :min_bid_amount
    rename_column :otc_markets, :visible, :enabled
  end
end
