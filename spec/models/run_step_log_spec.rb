# == Schema Information
#
# Table name: public.run_step_logs
#
#  id                     :integer          not null, primary key
#  run_id                 :integer          not null
#  step_id                :integer          not null
#  step_type              :string           not null
#  step_name              :string           not null
#  completed_successfully :boolean          default(FALSE), not null
#  step_errors            :jsonb            not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_run_step_logs_on_run_id_and_step_id_and_step_type  (run_id,step_id,step_type) UNIQUE
#  index_run_step_logs_on_step_id_and_step_type             (step_id,step_type)
#
# Foreign Keys
#
#  fk_rails_...  (run_id => runs.id)
#

describe RunStepLog do

  describe 'versioned by PaperTrail' do
    it { is_expected.to be_versioned }
  end

  describe "validations" do
    [:run, :step, :step_name].each do |att|
      it { should validate_presence_of(att) }
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
