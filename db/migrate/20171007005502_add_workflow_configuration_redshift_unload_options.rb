class AddWorkflowConfigurationRedshiftUnloadOptions < ActiveRecord::Migration[5.1]
  def change
    add_column :workflow_configurations, :redshift_unload_options, :text
  end
end
