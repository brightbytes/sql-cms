class ChangeDataFileAssociation < ActiveRecord::Migration[5.0]
  def up
    # At this point, we only have the Demo workflow and its DataFiles, so whatever
    Workflow.all.to_a.each(&:destroy)
    DataFile.all.to_a.each(&:destroy)
    remove_column :data_files, :customer_id

    add_column :data_files, :workflow_id, :integer, null: false
    execute "CREATE UNIQUE INDEX index_data_files_on_lowercase_name_and_workflow_id ON data_files USING btree (lower(name), workflow_id)"
    add_index :data_files, :workflow_id

    DataFile.reset_column_information
    WorkflowSeeder.seed
  end

  def down
    Workflow.all.to_a.each(&:destroy)
    DataFile.all.to_a.each(&:destroy)
    remove_column :data_files, :workflow_id

    add_column :data_files, :customer_id, :integer, null: false
    execute "CREATE UNIQUE INDEX index_data_files_on_lowercase_name_and_customer_id ON data_files USING btree (lower(name), customer_id)"
    add_index :data_files, :customer_id
  end
end
