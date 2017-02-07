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
#  index_run_step_logs_on_run_id  (run_id)
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
  end

  describe "associations" do
    it { should belong_to(:run) }
  end
end
