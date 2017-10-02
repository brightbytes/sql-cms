class AddRunDuration < ActiveRecord::Migration[5.1]
  def change
    add_column :runs, :finished_at, :datetime
    Run.update_all("finished_at = updated_at")
  end
end
