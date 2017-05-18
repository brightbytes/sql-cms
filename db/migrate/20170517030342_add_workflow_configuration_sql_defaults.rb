class AddWorkflowConfigurationSqlDefaults < ActiveRecord::Migration[5.1]
  def change
    add_column :workflows, :default_copy_from_sql, :string
    add_column :workflows, :default_copy_from_s3_file_type, :string
    add_column :workflows, :default_copy_to_sql, :string
    add_column :workflows, :default_copy_to_s3_file_type, :string
  end
end
