class TransformDisable < ActiveRecord::Migration[5.1]
  def change
    add_column :transforms, :enabled, :boolean, default: true, null: false
  end
end
