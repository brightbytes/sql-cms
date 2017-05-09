class FixCopyPasteIndexBug < ActiveRecord::Migration[5.1]
  def up
    remove_index :customers, name: :index_workflows_on_lowercase_slug
    execute "CREATE UNIQUE INDEX index_workflows_on_lowercase_slug ON workflows USING btree (lower(slug))"
  end

  def down
    remove_index :workflows, name: :index_workflows_on_lowercase_slug
    execute "CREATE UNIQUE INDEX index_workflows_on_lowercase_slug ON customers USING btree (lower(slug))"
  end
end
