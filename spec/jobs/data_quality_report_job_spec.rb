describe DataQualityReportJob do

  describe "#perform" do
    let!(:creator) { create(:user) }
    let!(:workflow) { create(:workflow) }
    let!(:data_quality_report) { create(:data_quality_report, workflow: workflow, sql: "SELECT COUNT(1) FROM :table", params: { table: :quick_test }) }

    before do
      run.create_schema
      run.execute_in_schema("CREATE TABLE quick_test (id SERIAL PRIMARY KEY, col INTEGER)")
      5.times { |i| run.execute_in_schema("INSERT INTO quick_test (col) VALUES (#{i})") }
    end

    let!(:run) do
      plan = ActiveModelSerializers::SerializableResource.new(workflow).as_json
      workflow.runs.create!(creator: creator, execution_plan: plan)
    end

    it "should store the result in the RunStepLog when invoked with valid SQL" do
      Sidekiq::Testing.inline! do
        DataQualityReportJob.perform_later(run_id: run.id, step_id: data_quality_report.id)
        run.reload
        logs = run.run_step_logs.where(step_type: 'data_quality_report').to_a
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
