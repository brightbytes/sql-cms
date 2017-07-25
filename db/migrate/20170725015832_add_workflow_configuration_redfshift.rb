class AddWorkflowConfigurationRedfshift < ActiveRecord::Migration[5.1]
  def change
    add_column :workflow_configurations, :redshift, :boolean, null: false, default: false
  end
end
