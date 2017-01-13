class CreateVersions < ActiveRecord::Migration

  def change
    create_table :versions do |t|
      t.with_options(null: false) do |tt|
        tt.string   :item_type
        tt.integer  :item_id
        tt.string   :event
        tt.datetime :created_at
      end

      t.integer :user_id
      t.string  :whodunnit

      t.jsonb :object
      t.jsonb :object_changes
    end

    add_index :versions, [:item_id, :item_type]
    add_index :versions, :user_id
    add_index :versions, :created_at

    add_foreign_key :versions, :users
  end

end
