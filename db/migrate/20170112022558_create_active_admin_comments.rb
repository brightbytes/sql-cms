class CreateActiveAdminComments < ActiveRecord::Migration[4.2]
  def self.up
    create_table :active_admin_comments do |t|
      t.with_options(null: false) do |tt|
        tt.string :namespace, default: ActiveAdmin.application.default_namespace
        tt.integer :resource_id
        tt.string :resource_type
        tt.integer :author_id
        tt.string :author_type
        tt.timestamps
      end
      t.text :body
    end
    add_index :active_admin_comments, [:resource_id, :resource_type, :created_at], name: :resource_created_at
    add_index :active_admin_comments, [:author_id, :author_type]
    add_index :active_admin_comments, :namespace
  end

  def self.down
    drop_table :active_admin_comments
  end
end
