class CreateWorkflowInterpolations < ActiveRecord::Migration[5.1]
  def change
    create_table :workflow_interpolations do |t|
      t.with_options(null: false) do |tt|
        tt.integer :workflow_id, index: true
        tt.string :name
        tt.string :slug
        tt.string :sql
      end
    end

    execute "CREATE UNIQUE INDEX index_workflow_interpolations_on_lowercase_slug_and_workflow_id ON workflow_interpolations USING btree (lower(slug), workflow_id)"
    execute "CREATE UNIQUE INDEX index_workflow_interpolations_on_lowercase_name_and_workflow_id ON workflow_interpolations USING btree (lower(name), workflow_id)"

    add_foreign_key :workflow_interpolations, :workflows

  end
end
