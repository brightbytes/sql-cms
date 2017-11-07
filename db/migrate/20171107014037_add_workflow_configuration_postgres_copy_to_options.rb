class AddWorkflowConfigurationPostgresCopyToOptions < ActiveRecord::Migration[5.1]
  def change
    add_column :workflow_configurations, :postgres_copy_to_options, :text
  end
end
