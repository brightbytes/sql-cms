describe RunManagerJob do

  describe "#perform" do

    let!(:creator) { create(:user, email: 'admin@example.com') }

    context "using the Demo Workflow and S3 file stubs" do
      before { WorkflowSeeder.seed }

      it "should successfully Run the entire Workflow" do
        Sidekiq::Testing.inline! do
          workflow = WorkflowSeeder.demo_workflow
          # We do this so that there's no schema collision on reruns
          workflow.update_attribute(:slug, "#{workflow.slug}_#{rand(10_000_000)}")

          run = WorkflowSeeder.demo_workflow_configuration.run!(creator)
          run.reload

          # Default debugging of global refactoring goof-ups, baby!!
          errors =  run.run_step_logs.erring.to_a
          dpp errors if errors.present?

          expect(run.successful?).to eq(true)
          expect(run.failed?).to eq(false)
          expect(run.running_or_crashed?).to eq(false)

          logs = run.run_step_logs
          expect(logs.size > 0).to eq(true)

          transform_count = run.execution_plan[:ordered_transform_groups].flatten.size
          expect(transform_count > 0).to eq(true)

          wdqr_count = run.execution_plan[:workflow_data_quality_reports].size
          expect(wdqr_count > 0).to eq(true)

          expect(logs.size).to eq(transform_count + wdqr_count)
        end
      end
    end

  end
end
