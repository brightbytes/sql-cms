class RemoveCopiedFromFields < ActiveRecord::Migration
  def up
    remove_column :workflows, :copied_from_workflow_id
    remove_column :transforms, :copied_from_transform_id
    remove_column :data_quality_reports, :copied_from_data_quality_report_id
  end

  def down
    add_column :workflows, :copied_from_workflow_id, :integer
    add_column :transforms, :copied_from_transform_id, :integer
    add_column :data_quality_reports, :copied_from_data_quality_report_id, :integer
  end
end
