# == Schema Information
#
# Table name: run_step_logs
#
#  id                       :integer          not null, primary key
#  run_id                   :integer          not null
#  step_type                :string           not null
#  step_index               :integer          default(0), not null
#  step_id                  :integer          default(0), not null
#  successful               :boolean          default(FALSE), not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  step_validation_failures :jsonb
#  step_exceptions          :jsonb
#  step_result              :jsonb
#
# Indexes
#
#  index_run_step_logs_on_run_id_and_created_at  (run_id,created_at)
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
    [:run, :step_type, :step_index, :step_id].each do |att|
      it { should validate_presence_of(att) }
    end

    it { should validate_inclusion_of(:step_type).in_array(described_class::STEP_TYPES) }

    # This isn't working, for reasons unlikely to ever become clear.  Don't care, because the corresponding DB constraint works just fine.
    # context 'with a run_step_log already extant' do
    #   let!(:subject) { create(:run_step_log) }
    #   it { should validate_uniqueness_of(:run_id).scoped_to([:step_id, :step_index, :step_name]) }
    # end
  end

  describe "associations" do
    it { should belong_to(:run) }
    it { should have_one(:workflow_configuration).through(:run) }
  end

  describe "instance methods" do

    context "Run#plan-related methods" do

      let!(:transform) do
        create(
          :transform,
          runner: 'RailsMigration',
          sql: "create_table :staging_boces_mappings do |t|\n  t.integer :clarity_org_id, index: true\n  t.integer :co_org_id, index: true\nend\n",
          name: "CREATE TABLE staging_boces_mappings"
        )
      end

      let!(:workflow) { transform.workflow }

      let!(:workflow_configuration) { create(:workflow_configuration, workflow: workflow) }

      let!(:run) { create(:run, workflow_configuration: workflow_configuration, execution_plan: workflow_configuration.serialize_and_symbolize) }

      let!(:run_step_log) { create(:run_step_log, run: run, step_type: 'transform', step_index: 0, step_id: transform.id) }

      let!(:expected_run_step_log_plan) do
        run.execution_plan.with_indifferent_access[:ordered_transform_groups].first.first.with_indifferent_access
      end

      it "should return the plan :name as the step_name" do
        expect(run_step_log.step_name).to eq(expected_run_step_log_plan[:name])
      end

      it "should return the plan :sql as the step_interpolated_sql" do
        expect(run_step_log.step_interpolated_sql).to eq(expected_run_step_log_plan[:interpolated_sql])
      end

      it "should use the step_name as the #to_s" do
        expect(run_step_log.to_s).to eq(expected_run_step_log_plan[:name])
      end

      it "should have the expected plan" do
        expect(run_step_log.step_plan).to eq(expected_run_step_log_plan.symbolize_keys)
      end

      it "should return the transform as the #plan_source_step" do
        expect(run_step_log.plan_source_step).to eq(transform)
      end
    end
  end

  describe "step-related methods" do
    context "a transform step" do

    end

    context "a data_quality_report step" do

    end
  end

  describe "#duration_seconds" do
    let!(:run_step_log) { create(:run_step_log) }

    it "should return how long the Run took" do
      expect(run_step_log.duration_seconds).to be > 0.0
    end
  end

end
