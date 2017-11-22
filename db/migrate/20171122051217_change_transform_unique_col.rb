class ChangeTransformUniqueCol < ActiveRecord::Migration[5.1]
  def up
    remove_index :transforms, name: :index_transforms_on_lowercase_name
    execute "CREATE UNIQUE INDEX index_transforms_on_lowercase_name_and_workflow_id ON transforms USING btree (lower(name), workflow_id)"
    # OMFG, can't believe I just now noticed this was missing.  Time for an immigrant checkup ...
    add_index :transforms, :workflow_id
  end

  def down
    remove_index :transforms, :workflow_id
    remove_index :transforms, name: :index_transforms_on_lowercase_name_and_workflow_id
    execute "CREATE UNIQUE INDEX index_transforms_on_lowercase_name ON transforms USING btree (lower(name))"
  end
end
