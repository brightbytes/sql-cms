class CreateWorkflowConfigurations < ActiveRecord::Migration[5.1]
  def up
    create_table :workflow_configurations do |t|
      t.with_options(null: false) do |tt|
        tt.integer :workflow_id
        tt.string :s3_region_name
        tt.string :s3_bucket_name
        tt.timestamps
      end
      t.integer :customer_id, index: true
      t.string :s3_file_path
    end

    add_index :workflow_configurations, [:workflow_id, :customer_id], unique: true, name: :index_unique_workflow_configurations_on_workflow_customer

    add_foreign_key :workflow_configurations, :workflows
    add_foreign_key :workflow_configurations, :customers

    Workflow.all.each do |workflow|
      WorkflowConfiguration.create!(
        workflow: workflow,
        customer_id: workflow.read_attribute(:customer_id),
        s3_region_name: workflow.s3_region_name,
        s3_bucket_name: workflow.s3_bucket_name,
        s3_file_path: workflow.s3_file_path
      )
    end

    [:customer_id, :s3_region_name, :s3_bucket_name, :s3_file_path, :shared].each { |col| remove_column :workflows, col }
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
