class MergeDataFileIntoTransform < ActiveRecord::Migration
  def up
    # Nuke these b/c only the Demo Workflow exists at this time, and it's easier to just re-seed
    WorkflowSeeder.demo_workflow.destroy!

    add_column :transforms, :s3_region_name, :string
    add_column :transforms, :s3_bucket_name, :string
    add_column :transforms, :s3_file_path, :string
    add_column :transforms, :s3_file_name, :string

    remove_column :transforms, :data_file_id

    drop_table :data_files
  end

  def down
    create_table :data_files do |t|
      t.with_options(null: false) do |tt|
        tt.string :name
        tt.integer :customer_id
        tt.string :file_type, default: :import
        tt.string :s3_region_name, default: 'us-west-2'
        tt.string :s3_bucket_name
        tt.string :s3_file_name
        tt.timestamps
      end
      t.string :s3_file_path
    end

    execute "CREATE UNIQUE INDEX index_data_files_on_lowercase_name_and_customer_id ON data_files USING btree (lower(name), customer_id)"
    add_index :data_files, :customer_id

    add_foreign_key :data_files, :customers

    add_column :transforms, :data_file_id, :integer
    add_index :transforms, :data_file_id
    add_foreign_key :transforms, :data_files

    remove_column :transforms, :s3_region_name
    remove_column :transforms, :s3_bucket_name
    remove_column :transforms, :s3_file_path
    remove_column :transforms, :s3_file_name
  end
end
