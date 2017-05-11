# == Schema Information
#
# Table name: workflow_dependencies
#
#  id                    :integer          not null, primary key
#  included_workflow_id  :integer          not null
#  including_workflow_id :integer          not null
#  created_at            :datetime         not null
#
# Indexes
#
#  index_workflow_dependencies_on_including_workflow_id       (including_workflow_id)
#  index_workflow_depenencies_on_independent_id_dependent_id  (included_workflow_id,including_workflow_id) UNIQUE
#

describe WorkflowDependency do

  describe 'versioned by PaperTrail' do
    it { is_expected.to be_versioned }
  end

  describe 'validations' do
    [:including_workflow, :included_workflow].each do |att|
      it { should validate_presence_of(att) }
    end

    context 'with a notification already extant' do
      let!(:subject) { create(:workflow_dependency) }
      it { should validate_uniqueness_of(:included_workflow).scoped_to(:including_workflow_id) }
    end

  end

  describe 'associations' do
    it { should belong_to(:included_workflow) }
    it { should belong_to(:including_workflow) }
  end

  describe 'instance methods' do

  end

end
