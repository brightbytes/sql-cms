class RemoveCustomerDeletedAt < ActiveRecord::Migration[5.1]
  def up
    Customer.where.not(deleted_at: nil).delete_all
    remove_column :customers, :deleted_at
  end

  def down
    add_column :customers, :deleted_at, :datetime
  end
end
