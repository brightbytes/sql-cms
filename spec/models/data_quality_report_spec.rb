# == Schema Information
#
# Table name: public.data_quality_reports
#
#  id          :integer          not null, primary key
#  workflow_id :integer          not null
#  name        :string           not null
#  sql         :text             not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  params      :jsonb
#
# Indexes
#
#  index_data_quality_reports_on_lowercase_name  (lower((name)::text)) UNIQUE
#  index_data_quality_reports_on_workflow_id     (workflow_id)
#
# Foreign Keys
#
#  fk_rails_...  (workflow_id => workflows.id)
#

describe DataQualityReport do

  describe 'versioned by PaperTrail' do
    it { is_expected.to be_versioned }
  end

  describe "validations" do
    [:name, :sql, :workflow].each do |att|
      it { should validate_presence_of(att) }
    end

    context "with a data_quality_report already extant" do
      let!(:subject) { create(:data_quality_report) }
      it { should validate_uniqueness_of(:name).case_insensitive }
    end

  end

  describe "associations" do
    it { should belong_to(:workflow) }
    it { should have_one(:customer) }
  end

  describe "instance methods" do
    context "#params" do
      let!(:subject) { build(:data_quality_report) }
      include_examples 'yaml helper methods'
    end
  end

end
