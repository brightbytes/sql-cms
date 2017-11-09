class MergeExportOptionsFields < ActiveRecord::Migration[5.1]
  def up
    rename_column :workflow_configurations, :redshift_unload_options, :export_transform_options
    WorkflowConfiguration.reset_column_information
    WorkflowConfiguration.where.not(postgres_copy_to_options: nil).update_all("export_transform_options = postgres_copy_to_options")
    remove_column :workflow_configurations, :postgres_copy_to_options
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
