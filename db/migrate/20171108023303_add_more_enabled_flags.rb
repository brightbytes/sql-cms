class AddMoreEnabledFlags < ActiveRecord::Migration[5.1]
  def change
    [:transform_validations, :workflow_data_quality_reports].each { |col| add_column col, :enabled, :boolean, default: true, null: false }
  end
end
