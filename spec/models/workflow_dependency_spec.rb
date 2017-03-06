# == Schema Information
#
# Table name: workflow_dependencies
#
#  id                      :integer          not null, primary key
#  independent_workflow_id :integer          not null
#  dependent_workflow_id   :integer          not null
#  created_at              :datetime         not null
#
# Indexes
#
#  index_workflow_dependencies_on_dependent_workflow_id       (dependent_workflow_id)
#  index_workflow_depenencies_on_independent_id_dependent_id  (independent_workflow_id,dependent_workflow_id) UNIQUE
#

describe WorkflowDependency do

  describe 'versioned by PaperTrail' do
    it { is_expected.to be_versioned }
  end

  describe 'validations' do
    [:dependent_workflow, :independent_workflow].each do |att|
      it { should validate_presence_of(att) }
    end

    context 'with a notification already extant' do
      let!(:subject) { create(:workflow_dependency) }
      it { should validate_uniqueness_of(:independent_workflow).scoped_to(:dependent_workflow_id) }
    end

    it "should not allow an unshared workflow to be an independent workflow" do
      expect(build(:workflow_dependency, independent_workflow: create(:workflow))).to_not be_valid
      expect(build(:workflow_dependency, independent_workflow: create(:shared_workflow))).to be_valid
    end

    it "should not allow a shared workflow to be a dependent workflow" do
      expect(build(:workflow_dependency, dependent_workflow: create(:shared_workflow))).to_not be_valid
      expect(build(:workflow_dependency, dependent_workflow: create(:workflow))).to be_valid
    end

  end

  describe 'associations' do
    it { should belong_to(:independent_workflow) }
    it { should belong_to(:dependent_workflow) }
  end

  describe 'instance methods' do

  end

end
