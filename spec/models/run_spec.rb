# frozen_string_literal: true
# == Schema Information
#
# Table name: public.runs
#
#  id             :integer          not null, primary key
#  workflow_id    :integer          not null
#  creator_id     :integer          not null
#  execution_plan :jsonb            not null
#  status         :string           default("unstarted"), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  schema_name    :string
#
# Indexes
#
#  index_runs_on_creator_id   (creator_id)
#  index_runs_on_workflow_id  (workflow_id)
#
# Foreign Keys
#
#  fk_rails_...  (creator_id => users.id)
#  fk_rails_...  (workflow_id => workflows.id)
#

describe Run do

  describe 'versioned by PaperTrail' do
    it { is_expected.to be_versioned }
  end

  describe "validations" do
    [:workflow, :creator, :execution_plan, :status].each do |att|
      it { should validate_presence_of(att) }
    end
  end

  describe "associations" do
    it { should have_many(:run_step_logs) }
    it { should belong_to(:creator) }
    it { should belong_to(:workflow) }
    it { should have_many(:transforms) }
    it { should have_many(:data_quality_reports) }
  end

  describe "callbacks" do

    context "after_create" do
      it "should set the schema_name" do
        run = build(:run)
        expect(run.schema_name).to be_nil
        expect(run.save).to eq(true)
        expect(run.schema_name).to eq("#{run.workflow}_run_#{run.id}")
      end
    end

    context "after_destroy" do
      it "should nuke any schema that was created" do
        run = create(:run)
        expect(run.schema_exists?).to eq(false)

        run.destroy
        expect(run.schema_exists?).to eq(false)

        run = create(:run)
        run.create_schema
        expect(run.schema_exists?).to eq(true)

        run.destroy
        expect(run.schema_exists?).to eq(false)
      end
    end
  end

  describe "instance methods" do

    describe "#schema_name" do
      it "should work like the boring method it is" do
        run = create(:run)
        expect(run.schema_name).to eq("#{run.workflow}_run_#{run.id}")
      end
    end

    describe "#to_s" do
      it "should return the schema_name" do
        run = create(:run)
        expect(run.to_s).to eq(run.schema_name)
      end
    end

    describe "#ordered_step_logs" do
      let!(:log_1) { create(:run_step_log) }
      let!(:run) { log_1.run }
      let!(:log_2) { create(:run_step_log, run: run) }
      let!(:log_3) { create(:run_step_log, run: run) }
      let!(:log_4) { create(:run_step_log, run: run) }

      it "should order the logs by ID, which is effectively execution order" do
        expect(run.ordered_step_logs).to eq([log_1, log_2, log_3, log_4])
      end
    end

    describe "#failed?" do
      let!(:run) { create(:run) }

      it "should return true when any step log has errors" do
        2.times { create(:run_step_log, run: run) }
        create(:run_step_log, run: run, completed: true)
        expect(run.failed?).to eq(false)
        create(:run_step_log, run: run, step_errors: { whatever: :dude })
        expect(run.failed?).to eq(true)
      end
    end

    context 'with a run having a cheesey serialized workflow' do
      include_examples 'a workflow serialized into a run'

      describe "#transform_group_transform_ids" do
        it "should return the expected transform ids" do
          expect(Set.new(run.transform_group_transform_ids(0))).to eq(Set.new([independent_transform, least_dependent_transform, first_child_transform].map(&:id)))
          expect(Set.new(run.transform_group_transform_ids(1))).to eq(Set.new([less_dependent_transform, another_less_dependent_transform].map(&:id)))
          expect(Set.new(run.transform_group_transform_ids(2))).to eq(Set.new([most_dependent_transform].map(&:id)))
          expect(run.transform_group_transform_ids(3)).to eq(nil)
        end
      end

      describe "#data_quality_report_ids" do
        it "should return the expected data_quality_report ids" do
          expect(Set.new(run.data_quality_report_ids)).to eq(Set.new([data_quality_report_1, data_quality_report_2, data_quality_report_3].map(&:id)))
        end
      end

    end

    # describe "#with_run_step_log_tracking and #ordered_step_logs" do
    #   it "should create a new RunStatus for the Run and flag it as successful when no exception is raised" do
    #     run = create(:run)

    #     expect(run.with_run_step_log_tracking(run.pipeline) { nil }).to eq(true)

    #     statuses = run.ordered_step_logs
    #     expect(statuses.size).to eq(1)
    #     status = statuses.first
    #     expect(status.run).to eq(run) # duh
    #     expect(status.step).to eq(run.pipeline)
    #     expect(status.step_successful).to be true
    #     expect(status.step_errors).to be_empty
    #   end

    #   it "should create a new RunStatus for the Run and flag it as unsuccessful and preserve the erring IDs in the error" do
    #     run = create(:run)
    #     error_h = { 'ids_failing_validation' => %w(1 5 111) }

    #     expect(run.with_run_step_log_tracking(run.pipeline) { error_h }).to eq(false)

    #     statuses = run.ordered_step_logs
    #     expect(statuses.size).to eq(1)
    #     status = statuses.first
    #     expect(status.run).to eq(run) # duh
    #     expect(status.step).to eq(run.pipeline)
    #     expect(status.step_successful).to be false
    #     expect(status.step_errors).to eq(error_h)
    #   end

    #   it "should create a new RunStatus for the Run and add exception details when an exception is raised" do
    #     run = create(:run)

    #     error_text = "Boom!"

    #     expect(run.with_run_step_log_tracking(run.pipeline) { raise error_text }).to eq(false)

    #     statuses = run.ordered_step_logs
    #     expect(statuses.size).to eq(1)
    #     status = statuses.first
    #     expect(status.run).to eq(run) # duh
    #     expect(status.step).to eq(run.pipeline)
    #     expect(status.step_successful).to be false
    #     errors = status.step_errors
    #     expect(errors).to_not be_empty
    #     expect(errors['class_and_message']).to eq("#<RuntimeError: Boom!>")
    #     expect(errors['backtrace']).to_not be_empty
    #   end
    # end

    # describe "#create_schema_and_tables!" do
    #   context "for a Pipeline with multiple DDL expressions" do
    #     let!(:pipeline) do
    #       create(
    #         :pipeline,
    #         ddl: %q{
    #           /* This is a test comment, and is currently the only comment syntax allowed: the -- syntax doesn't work */

    #           CREATE TABLE staging_boces_mappings (id serial primary key, clarity_org_id integer, co_org_id integer);
    #           CREATE TABLE silly (id serial primary key, stringy character varying NOT NULL);
    #         }
    #       )
    #     end

    #     let!(:run) { create(:run, pipeline: pipeline) }

    #     it "should create all the specified tables" do
    #       run.create_schema_and_tables!
    #       expect(run.schema_exists?).to be true

    #       ar_result = run.select_all_in_schema("SELECT count(1) FROM staging_boces_mappings")
    #       expect(ar_result.rows.first.first.to_i).to eq(0)

    #       ar_result = run.select_all_in_schema("SELECT count(1) FROM silly")
    #       expect(ar_result.rows.first.first.to_i).to eq(0)
    #     end
    #   end
    # end

  end
end
