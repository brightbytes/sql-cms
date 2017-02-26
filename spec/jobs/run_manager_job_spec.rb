describe RunManagerJob do

  describe "#perform" do

    let!(:creator) { create(:user, email: 'aaron@brightbytes.net') }

    context "using the Demo Workflow and S3 file stubs" do
      before { WorkflowSeeder.seed }

      it "should successfully Run the entire Workflow" do
        Sidekiq::Testing.inline! do
          workflow = WorkflowSeeder.demo_workflow
          # We do this so that there's no schema collision on reruns
          workflow.update_attribute(:slug, "#{workflow.slug}_#{rand(10_000_000)}")

          run = workflow.run!(creator)
          run.reload

          # Default debugging of global refactoring goof-ups, baby!!
          errors =  run.run_step_logs.erring.to_a
          dpp errors if errors.present?

          expect(run.successful?).to eq(true)
          expect(run.failed?).to eq(false)
          expect(run.running_or_crashed?).to eq(false)

          logs = run.run_step_logs
          expect(logs.size > 0).to eq(true)

          transforms = run.transforms
          expect(transforms.size > 0).to eq(true)

          data_quality_reports = run.data_quality_reports
          expect(data_quality_reports.size > 0).to eq(true)

          expect(logs.size).to eq(transforms.size + data_quality_reports.size)
        end
      end
    end

  end
end
