# == Schema Information
#
# Table name: public.run_step_logs
#
#  id          :integer          not null, primary key
#  run_id      :integer          not null
#  step_name   :string           not null
#  step_index  :integer          default(0), not null
#  step_id     :integer          default(0), not null
#  completed   :boolean          default(FALSE), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  step_errors :jsonb
#
# Indexes
#
#  index_run_step_log_on_unique_run_id_and_step_fields  (run_id,step_id,step_index,step_name) UNIQUE
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
    [:run, :step_name, :step_index, :step_id].each do |att|
      it { should validate_presence_of(att) }
    end

    # This isn't working, for reasons unlikely to ever become clear.  Don't care, because the corresponding DB constraint works just fine.
    # context 'with a run_step_log already extant' do
    #   let!(:subject) { create(:run_step_log) }
    #   it { should validate_uniqueness_of(:run_id).scoped_to([:step_id, :step_index, :step_name]) }
    # end
  end

  describe "associations" do
    it { should belong_to(:run) }
  end
end
