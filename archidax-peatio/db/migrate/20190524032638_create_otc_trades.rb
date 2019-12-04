class CreateOtcTrades < ActiveRecord::Migration
  def change
    create_table :otc_trades do |t|
      t.decimal  "price",                    precision: 32, scale: 16, null: false
      t.decimal  "volume",                   precision: 32, scale: 16, null: false
      t.integer  "ask_id",        limit: 4,                            null: false
      t.integer  "bid_id",        limit: 4,                            null: false
      t.integer  "trend",         limit: 4,                            null: false
      t.string   "otc_market_id",     limit: 20,                           null: false
      t.integer  "ask_member_id", limit: 4,                            null: false
      t.integer  "bid_member_id", limit: 4,                            null: false
      t.decimal  "funds",                    precision: 32, scale: 16, null: false
      t.datetime "created_at",                                         null: false
      t.datetime "updated_at",                                         null: false
    end

    add_index "otc_trades", ["ask_id"], name: "index_otc_trades_on_ask_id", using: :btree
    add_index "otc_trades", ["ask_member_id", "bid_member_id"], name: "index_otc_trades_on_ask_member_id_and_bid_member_id", using: :btree
    add_index "otc_trades", ["bid_id"], name: "index_otc_trades_on_bid_id", using: :btree
    add_index "otc_trades", ["otc_market_id", "created_at"], name: "index_otc_trades_on_otc_market_id_and_created_at", using: :btree
  end
end
