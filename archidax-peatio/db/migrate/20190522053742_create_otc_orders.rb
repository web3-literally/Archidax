class CreateOtcOrders < ActiveRecord::Migration
  def change
    create_table :otc_orders do |t|
      t.string "bid", limit: 10, null: false
      t.string "ask", limit: 10, null: false
      t.string "otc_market_id", limit: 20, null: false
      t.integer "member_id", limit: 4, null: false
      t.decimal "price", precision: 32, scale: 16
      t.decimal "volume", precision: 32, scale: 16, null: false
      t.decimal "origin_volume", precision: 32, scale: 16, null: false
      t.decimal "fee", precision: 32, scale: 16, default: 0.0, null: false
      t.integer "state", limit: 4, null: false
      t.string "type", limit: 8, null: false
      t.string "ord_type", limit: 30, null: false
      t.decimal "locked", precision: 32, scale: 16, default: 0.0, null: false
      t.decimal "origin_locked", precision: 32, scale: 16, default: 0.0, null: false
      t.decimal "funds_received", precision: 32, scale: 16, default: 0.0
      t.integer "trades_count", limit: 4, default: 0, null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end
  end
end
