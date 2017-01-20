# frozen_string_literal: true
class ApplicationTables < ActiveRecord::Migration
  def change

    create_table :customers do |t|
      t.with_options(null: false) do |tt|
        tt.string :name
        tt.string :slug
        tt.timestamps
      end
      t.datetime :deleted_at
    end

    execute "CREATE UNIQUE INDEX index_customers_on_lowercase_name ON customers USING btree (lower(name))"
    execute "CREATE UNIQUE INDEX index_customers_on_lowercase_slug ON customers USING btree (lower(slug))"

    create_table :data_files do |t|
      t.with_options(null: false) do |tt|
        tt.string :name
        tt.jsonb :metadata, default: '{}'
        tt.integer :customer_id
        tt.string :upload_file_name
        tt.string :upload_content_type
        tt.integer :upload_file_size
        tt.datetime :upload_updated_at
        tt.timestamps
      end
      t.datetime :deleted_at
    end

    execute "CREATE UNIQUE INDEX index_data_files_on_lowercase_name ON data_files USING btree (lower(name))"
    add_index :data_files, :customer_id

    add_foreign_key :data_files, :customers

    create_table :workflows do |t|
      t.with_options(null: false) do |tt|
        tt.string :name
        tt.string :schema_base_name
        tt.string :dbms, default: :postgres
        tt.integer :customer_id
        tt.timestamps
      end
      t.integer :copied_from_workflow_id
    end

    execute "CREATE UNIQUE INDEX index_workflows_on_lowercase_name ON workflows USING btree (lower(name))"
    execute "CREATE UNIQUE INDEX index_workflows_on_lowercase_schema_base_name ON workflows USING btree (lower(schema_base_name))"
    add_index :workflows, :customer_id
    add_index :workflows, :copied_from_workflow_id

    add_foreign_key :workflows, :workflows, column: :copied_from_workflow_id
    add_foreign_key :workflows, :customers


    create_table :notifications do |t|
      t.with_options(null: false) do |tt|
        tt.integer :user_id
        tt.integer :workflow_id
        tt.timestamps
      end
    end

    add_index :notifications, :user_id
    add_index :notifications, [:workflow_id, :user_id], unique: true

    add_foreign_key :notifications, :users
    add_foreign_key :notifications, :workflows


    create_table :transforms do |t|
      t.with_options(null: false) do |tt|
        tt.string :name
        tt.string :transform_type
        tt.integer :workflow_id
        tt.jsonb :sql_params, default: '{}'
        tt.text :sql
        tt.timestamps
      end
      t.text :transcompiled_source
      t.string :transcompiled_source_language
      t.integer :data_file_id
      t.integer :copied_from_transform_id
    end

    execute "CREATE UNIQUE INDEX index_transforms_on_lowercase_name ON transforms USING btree (lower(name))"
    add_index :transforms, :workflow_id
    add_index :transforms, :data_file_id
    add_index :transforms, :copied_from_transform_id

    add_foreign_key :transforms, :workflows
    add_foreign_key :transforms, :data_files
    add_foreign_key :transforms, :transforms, column: :copied_from_transform_id

    create_table :transform_dependencies do |t|
      t.with_options(null: false) do |tt|
        tt.integer :prerequisite_transform_id
        tt.integer :postrequisite_transform_id
        tt.datetime :created_at
      end
    end

    add_index :transform_dependencies, [:postrequisite_transform_id, :prerequisite_transform_id], unique: true, name: :index_transform_dependencies_on_unique_transform_ids
    add_index :transform_dependencies, :prerequisite_transform_id
    add_foreign_key :transform_dependencies, :transforms, column: :postrequisite_transform_id
    add_foreign_key :transform_dependencies, :transforms, column: :prerequisite_transform_id


    create_table :validations do |t|
      t.with_options(null: false) do |tt|
        tt.string :name
        tt.boolean :immutable, default: false
        tt.text :sql
        tt.timestamps
      end
      t.text :transcompiled_source
      t.string :transcompiled_source_language
    end

    execute "CREATE UNIQUE INDEX index_validations_on_lowercase_name ON validations USING btree (lower(name))"

    create_table :transform_validations do |t|
      t.with_options(null: false) do |tt|
        tt.integer :transform_id
        tt.integer :validation_id
        tt.jsonb :sql_params, default: '{}'
        tt.timestamps
      end
    end

    add_index :transform_validations, [:transform_id, :validation_id, :sql_params], unique: true, name: :index_transform_validations_on_transform_validation_params
    add_index :transform_validations, :validation_id

    add_foreign_key :transform_validations, :transforms
    add_foreign_key :transform_validations, :validations

    create_table :data_quality_checks do |t|
      t.with_options(null: false) do |tt|
        tt.integer :workflow_id
        tt.string :name
        tt.jsonb :sql_params, default: '{}'
        tt.text :sql
        tt.timestamps
      end
      t.text :transcompiled_source
      t.string :transcompiled_source_language
      t.integer :copied_from_data_quality_check_id
    end

    add_index :data_quality_checks, :workflow_id
    add_index :data_quality_checks, :copied_from_data_quality_check_id

    add_foreign_key :data_quality_checks, :workflows
    add_foreign_key :data_quality_checks, :data_quality_checks, column: :copied_from_data_quality_check_id


    create_table :runs do |t|
      t.with_options(null: false) do |tt|
        tt.integer :workflow_id
        tt.integer :creator_id
        tt.jsonb :execution_plan
        tt.timestamps
      end
    end

    add_index :runs, :workflow_id
    add_index :runs, :creator_id

    add_foreign_key :runs, :workflows
    add_foreign_key :runs, :users, column: :creator_id

    create_table :step_logs do |t|
      t.with_options(null: false) do |tt|
        tt.integer :run_id
        tt.integer :step_id
        tt.string :step_type
        tt.string :step_name # Denormalization to ease debugging
        tt.boolean :completed_successfully, default: false
        tt.jsonb :errors, default: '{}'
        tt.timestamps
      end
    end

    add_index :step_logs, [:run_id, :step_id, :step_type], unique: true
    add_index :step_logs, [:step_id, :step_type]

    add_foreign_key :step_logs, :runs

  end
end
