class AddNameFiledsToMembers < ActiveRecord::Migration
  def change
    add_column :members, :name, :string, after: :email
  end
end
