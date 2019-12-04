class RemoveOrdTypeFromOtcOrder < ActiveRecord::Migration
  def change
    remove_column :otc_orders, :ord_type if column_exists?(:otc_orders, :ord_type)
  end
end
