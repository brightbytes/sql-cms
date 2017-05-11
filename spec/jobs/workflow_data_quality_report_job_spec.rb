describe WorkflowDataQualityReportJob do

  describe "#perform" do
    let!(:creator) { create(:user) }
    let!(:workflow_configuration) { create(:workflow_configuration) }
    let!(:workflow) { workflow_configuration.workflow }
    let!(:workflow_data_quality_report) do
      create(:workflow_data_quality_report, workflow: workflow, data_quality_report: DataQualityReport.table_count, params: { table_name: :quick_test })
    end

    before do
      run.create_schema
      run.execute_in_schema("CREATE TABLE quick_test (id SERIAL PRIMARY KEY, col INTEGER)")
      5.times { |i| run.execute_in_schema("INSERT INTO quick_test (col) VALUES (#{i})") }
    end

    let!(:run) do
      workflow_configuration.runs.create!(creator: creator, execution_plan: workflow_configuration.serialize_and_symbolize)
    end

    it "should store the result in the RunStepLog when invoked with valid SQL" do
      Sidekiq::Testing.inline! do
        WorkflowDataQualityReportJob.perform_later(run_id: run.id, step_id: workflow_data_quality_report.id)
        run.reload
        logs = run.run_step_logs.where(step_type: 'workflow_data_quality_report').to_a
        expect(logs.size).to eq(1)
        log = logs.first
        expect(log.step_exceptions).to eq(nil)
        expect(log.step_validation_failures).to eq(nil)
        expect(log.successful?).to eq(true)
        expect(log.step_result).to eq([{ 'count' => 5 }])
      end
    end
  end

end
