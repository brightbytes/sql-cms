class RemoveSupersededFields < ActiveRecord::Migration[5.1]
  def up
    remove_column :workflows, :default_copy_from_sql
    remove_column :workflows, :default_copy_from_s3_file_type
    remove_column :workflows, :default_copy_to_sql
    remove_column :workflows, :default_copy_to_s3_file_type
  end

  def down
    add_column :workflows, :default_copy_from_sql, :string
    add_column :workflows, :default_copy_from_s3_file_type, :string
    add_column :workflows, :default_copy_to_sql, :string
    add_column :workflows, :default_copy_to_s3_file_type, :string
  end
end
