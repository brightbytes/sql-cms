class ImmutableRuns < ActiveRecord::Migration[5.1]
  def change
    add_column :runs, :immutable, :boolean, default: false, null: false
  end
end
