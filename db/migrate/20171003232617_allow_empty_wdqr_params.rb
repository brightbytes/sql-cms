class AllowEmptyWdqrParams < ActiveRecord::Migration[5.1]
  def up
    change_column :workflow_data_quality_reports, :params, :jsonb, null: true
  end

  def down
    change_column :workflow_data_quality_reports, :params, :jsonb, null: false
  end

end
