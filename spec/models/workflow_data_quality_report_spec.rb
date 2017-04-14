# == Schema Information
#
# Table name: public.workflow_data_quality_reports
#
#  id                     :integer          not null, primary key
#  workflow_id            :integer          not null
#  data_quality_report_id :integer          not null
#  params                 :jsonb            not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
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
    [:workflow, :params, :data_quality_report].each do |att|
      it { should validate_presence_of(att) }
    end
  end

  describe "associations" do
    it { should belong_to(:workflow) }
    it { should belong_to(:data_quality_report) }
  end

  describe "instance methods" do

    context "#params" do
      let!(:subject) { build(:workflow_data_quality_report) }
      include_examples 'yaml helper methods'
    end

  end
end
