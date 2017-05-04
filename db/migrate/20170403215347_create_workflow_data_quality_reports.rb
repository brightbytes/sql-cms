class CreateWorkflowDataQualityReports < ActiveRecord::Migration[4.2]

  def up
    # LOL - just realized this was missing; whoops
    add_index :transform_validations, :transform_id

    create_table :workflow_data_quality_reports do |t|
      t.with_options(null: false) do |tt|
        # Note we can't do the traditional 2-column unique index b/c the params would need to be part of the uniqueness ... but that no-workie with JSONB
        tt.integer :workflow_id, index: true
        tt.integer :data_quality_report_id, index: true
        tt.jsonb :params
        tt.timestamps
      end
    end

    add_foreign_key :workflow_data_quality_reports, :workflows
    add_foreign_key :workflow_data_quality_reports, :data_quality_reports

    # At this time, we only have the table count reports in both the demo workflow and actual production workflow, so we just patch-up on the fly here:
    change_column_null :data_quality_reports, :workflow_id, true
    add_column :data_quality_reports, :immutable, :boolean, default: false
    DataQualityReport.reset_column_information
    DataQualityReportSeeder.seed
    dqrs = DataQualityReport.where("workflow_id IS NOT NULL").to_a
    dqrs.each do |dqr|
      WorkflowDataQualityReport.create!(
        workflow_id: dqr.workflow_id,
        data_quality_report: DataQualityReport.table_count,
        params: dqr.params || { table_name: :fix_me }
      )
      dqr.destroy
    end

    [:workflow_id, :params].each { |col| remove_column :data_quality_reports, col }

    # Because we're changing execution plan internal names:
    Run.all.each(&:destroy)
  end

  def down
    # Shine doing this better: not worth the effort at this point
    raise ActiveRecord::IrreversibleMigration
  end
end
