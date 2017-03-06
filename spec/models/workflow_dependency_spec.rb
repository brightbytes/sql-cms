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

  end

  describe 'associations' do
    it { should belong_to(:independent_workflow) }
    it { should belong_to(:dependent_workflow) }
  end

  describe 'instance methods' do

  end

end
