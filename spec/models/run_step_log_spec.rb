
describe RunStepLog do

  describe 'versioned by PaperTrail' do
    it { is_expected.to be_versioned }
  end

  describe "validations" do
    [:run, :step, :step_name].each do |att|
      it { should validate_presence_of(att) }
    end

    it "should validate that step_errors is not null, but allow blank" do
      pt = create(:run_step_log)
      pt.step_errors = nil
      expect(pt.valid?).to be false

      pt.step_errors = {}
      expect(pt.valid?).to be true
    end

    context "with a run_step_log already extant" do
      let!(:subject) { create(:run_step_log) }
      it { should validate_uniqueness_of(:run).scoped_to([:step_id, :step_type]) }
    end

  end

  describe "associations" do
    it { should belong_to(:run) }
    it { should belong_to(:step) }
  end
end
