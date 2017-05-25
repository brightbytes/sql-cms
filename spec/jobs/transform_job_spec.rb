describe TransformJob do

  describe "#perform" do
    let!(:creator) { create(:user) }
    let!(:workflow_configuration) { create(:workflow_configuration) }
    let!(:workflow) { workflow_configuration.workflow }

    context "on a Transform using the 'SqlTransform' runner" do
      let!(:transform) do
        create(:transform, workflow: workflow, runner: 'Sql', sql: "INSERT INTO target_table (col_target) SELECT col_source FROM source_table WHERE col_source < 3")
      end

      context "with a validation that passes" do
        let!(:transform_validation) do
          create(:transform_validation, transform: transform, validation: Validation.non_null, params: { table_name: :target_table, column_name: :col_target })
        end

        let!(:run) do
          workflow_configuration.runs.create!(creator: creator, execution_plan: workflow_configuration.serialize_and_symbolize)
        end

        before do
          run.create_schema
          run.execute_in_schema("CREATE TABLE source_table (id SERIAL PRIMARY KEY, col_source INTEGER)")
          run.execute_in_schema("CREATE TABLE target_table (id SERIAL PRIMARY KEY, col_target INTEGER)")
          5.times { |i| run.execute_in_schema("INSERT INTO source_table (col_source) VALUES (#{i})") }
        end

        it "should successfully run the transform and log the result" do
          Sidekiq::Testing.inline! do
            TransformJob.perform_later(run_id: run.id, step_index: 0, step_id: transform.id)
            run.reload
            logs = run.run_step_logs.where(step_type: 'transform').to_a
            log = logs.first
            expect(log.step_exceptions).to eq(nil)
            expect(log.step_validation_failures).to eq(nil)
            expect(log.successful?).to eq(true)
            expect(run.select_value_in_schema("SELECT COUNT(1) FROM target_table").to_i).to eq(3)
          end
        end
      end

      context "with a validation that fails" do
        let!(:transform_validation) do
          ValidationSeeder.seed
          create(:transform_validation, transform: transform, validation: Validation.find_by(name: 'Column :table_name.:column_name is Less Than :value'), params: { table_name: :target_table, column_name: :col_target, value: 1 })
        end

        let!(:run) do
          workflow_configuration.runs.create!(creator: creator, execution_plan: workflow_configuration.serialize_and_symbolize)
        end

        before do
          run.create_schema
          run.execute_in_schema("CREATE TABLE source_table (id SERIAL PRIMARY KEY, col_source INTEGER)")
          run.execute_in_schema("CREATE TABLE target_table (id SERIAL PRIMARY KEY, col_target INTEGER)")
          5.times { |i| run.execute_in_schema("INSERT INTO source_table (col_source) VALUES (#{i})") }
        end

        it "should successfully run the transform and log the result" do
          Sidekiq::Testing.inline! do
            TransformJob.perform_later(run_id: run.id, step_index: 0, step_id: transform.id)
            run.reload
            logs = run.run_step_logs.where(step_type: 'transform').to_a
            log = logs.first
            expect(log.step_validation_failures&.first&.fetch('ids_failing_validation', nil)).to eq("2, 3")
            expect(log.successful?).to eq(false)
            expect(run.select_value_in_schema("SELECT COUNT(1) FROM target_table").to_i).to eq(3)
          end
        end
      end


    end
  end

end
