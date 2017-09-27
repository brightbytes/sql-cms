class AddMissingTimestamps < ActiveRecord::Migration[5.1]
  def change
    # None exist yet.
    Interpolation.delete_all
    add_column :interpolations, :created_at, :datetime, null: false
    add_column :interpolations, :updated_at, :datetime, null: false
  end
end
