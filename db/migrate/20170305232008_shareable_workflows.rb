class ShareableWorkflows < ActiveRecord::Migration

  def up
    change_column_null :workflows, :customer_id, true
    rename_column :workflows, :template, :shared

    create_table :workflow_dependencies do |t|
      t.with_options(null: false) do |tt|
        tt.integer :included_workflow_id, foreign_key: true
        tt.integer :including_workflow_id, foreign_key: true, index: true
        tt.datetime :created_at
      end
    end

    add_index :workflow_dependencies, [:included_workflow_id, :including_workflow_id], unique: true, name: :index_workflow_depenencies_on_independent_id_dependent_id
  end

  def down
    # change_column_null :workflows, :customer_id, false
    rename_column :workflows, :shared, :template

    drop_table :workflow_dependencies
  end

end
