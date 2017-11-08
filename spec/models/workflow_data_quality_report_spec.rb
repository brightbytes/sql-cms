# == Schema Information
#
# Table name: public.workflow_data_quality_reports
#
#  id                     :integer          not null, primary key
#  workflow_id            :integer          not null
#  data_quality_report_id :integer          not null
#  params                 :jsonb
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  enabled                :boolean          default(TRUE), not null
#
# Indexes
#
#  index_workflow_data_quality_reports_on_data_quality_report_id  (data_quality_report_id)
#  index_workflow_data_quality_reports_on_workflow_id             (workflow_id)
#
# Foreign Keys
#
#  fk_rails_...  (data_quality_report_id => data_quality_reports.id)
#  fk_rails_...  (workflow_id => workflows.id)
#

describe WorkflowDataQualityReport do

  describe 'versioned by PaperTrail' do
    it { is_expected.to be_versioned }
  end

  describe "validations" do
    [:workflow, :data_quality_report].each do |att|
      it { should validate_presence_of(att) }
    end
  end

  describe "associations" do
    it { should belong_to(:workflow) }
    it { should belong_to(:data_quality_report) }
  end

  describe "instance methods" do

    context "#enabled" do
      it "should prevent the WorkflowDataQualityReport from being executed" do
        wqdr = create(:workflow_data_quality_report, enabled: false)
        workflow_configuration = create(:workflow_configuration, workflow: wqdr.workflow)
        run = workflow_configuration.runs.create!(creator: create(:user), execution_plan: workflow_configuration.serialize_and_symbolize)
        Sidekiq::Testing.inline! do
          WorkflowDataQualityReportJob.perform_later(run_id: run.id, step_id: wqdr.id)
          run.reload
          logs = run.run_step_logs.where(step_type: 'workflow_data_quality_report').to_a
          log = logs.first
          expect(log.step_exceptions).to eq(nil)
          expect(log.step_validation_failures).to eq(nil)
          expect(log.successful?).to eq(true)
          expect(log.step_result).to eq({ 'workflow_data_quality_report_disabled' => true })
        end
      end
    end

    context "#params" do
      let!(:subject) { build(:workflow_data_quality_report) }
      include_examples 'yaml helper methods'
    end

  end
end
