describe RunManagerJob do

  describe "#perform" do

    let!(:creator) { create(:user, email: 'aaron@brightbytes.net') }

    context "using the Demo Workflow" do
      before { WorkflowSeeder.seed }

      it "should successfully Run the entire Workflow" do
        Sidekiq::Testing.inline! do
          WorkflowSeeder.demo_workflow.run!(creator)
        end

        # Add tests here.

      end
    end

  end
end
