class AddOfferIdToOtcOrders < ActiveRecord::Migration
  def change
    add_column :otc_orders, :offer_id, :integer, after: :member_id
    add_column :otc_orders, :msg, :string, after: :offer_id
    add_index :otc_orders, :offer_id
  end

end
