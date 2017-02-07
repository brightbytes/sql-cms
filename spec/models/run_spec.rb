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

    describe "#name" do
      it "should return the schema_name" do
        run = create(:run)
        expect(run.name).to eq(run.schema_name)
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

      describe "#transform_group" do
        it "should return the expected transform hashes" do
          expect(run.transform_group(0)).to eq(run.execution_plan[:ordered_transform_groups][0])
          expect(run.transform_group(1)).to eq(run.execution_plan[:ordered_transform_groups][1])
          expect(run.transform_group(2)).to eq(run.execution_plan[:ordered_transform_groups][2])
          expect(run.transform_group(3)).to eq(nil)
        end
      end

      describe "#transform_group_transform_ids" do
        it "should return the expected transform ids" do
          expect(Set.new(run.transform_group_transform_ids(0))).to eq(Set.new([independent_transform, least_dependent_transform, first_child_transform].map(&:id)))
          expect(Set.new(run.transform_group_transform_ids(1))).to eq(Set.new([less_dependent_transform, another_less_dependent_transform].map(&:id)))
          expect(Set.new(run.transform_group_transform_ids(2))).to eq(Set.new([most_dependent_transform].map(&:id)))
          expect(run.transform_group_transform_ids(3)).to eq(nil)
        end
      end

      describe "#transform_plan" do
        it "should return the expected transform hashes" do
          expect(run.transform_plan(step_index: 0, transform_id: independent_transform.id)).to eq(ActiveModelSerializers::SerializableResource.new(independent_transform).as_json)
          expect(run.transform_plan(step_index: 0, transform_id: least_dependent_transform.id)).to eq(ActiveModelSerializers::SerializableResource.new(least_dependent_transform).as_json)
          expect(run.transform_plan(step_index: 0, transform_id: first_child_transform.id)).to eq(ActiveModelSerializers::SerializableResource.new(first_child_transform).as_json)
          expect(run.transform_plan(step_index: 1, transform_id: less_dependent_transform.id)).to eq(ActiveModelSerializers::SerializableResource.new(less_dependent_transform).as_json)
          expect(run.transform_plan(step_index: 1, transform_id: another_less_dependent_transform.id)).to eq(ActiveModelSerializers::SerializableResource.new(another_less_dependent_transform).as_json)
          expect(run.transform_plan(step_index: 2, transform_id: most_dependent_transform.id)).to eq(ActiveModelSerializers::SerializableResource.new(most_dependent_transform).as_json)
          expect(run.transform_plan(step_index: 2, transform_id: 123421234324)).to eq(nil)
          expect(run.transform_plan(step_index: 3, transform_id: independent_transform.id)).to eq(nil)
        end
      end

      describe "transform_group_successfully_completed?" do

        it "should return true when all transform group steps are successfully_completed" do
          create(:run_step_log, run: run, completed: true, step_name: 'ordered_transform_groups', step_index: 0, step_id: independent_transform.id)
          create(:run_step_log, run: run, completed: true, step_name: 'ordered_transform_groups', step_index: 0, step_id: least_dependent_transform.id)
          create(:run_step_log, run: run, completed: true, step_name: 'ordered_transform_groups', step_index: 0, step_id: first_child_transform.id)
          expect(run.transform_group_successfully_completed?(0)).to eq(true)
        end

        it "should return false when one of the transforms has an error" do
          create(:run_step_log, run: run, completed: true, step_name: 'ordered_transform_groups', step_index: 0, step_id: independent_transform.id)
          create(:run_step_log, run: run, step_errors: { too_bad: :dude }, step_name: 'ordered_transform_groups', step_index: 0, step_id: least_dependent_transform.id)
          create(:run_step_log, run: run, completed: true, step_name: 'ordered_transform_groups', step_index: 0, step_id: first_child_transform.id)
          expect(run.transform_group_successfully_completed?(0)).to eq(false)
        end

        it "should return false when one of the transforms hasn't been completed" do
          create(:run_step_log, run: run, completed: true, step_name: 'ordered_transform_groups', step_index: 0, step_id: independent_transform.id)
          create(:run_step_log, run: run, completed: false, step_name: 'ordered_transform_groups', step_index: 0, step_id: least_dependent_transform.id)
          create(:run_step_log, run: run, completed: true, step_name: 'ordered_transform_groups', step_index: 0, step_id: first_child_transform.id)
          expect(run.transform_group_successfully_completed?(0)).to eq(false)
        end

      end

      describe "#data_quality_reports" do
        it "should return the expected data_quality_reports hash" do
          expect(run.data_quality_reports).to eq(run.execution_plan[:data_quality_reports])
        end
      end

      describe "#data_quality_report_ids" do
        it "should return the expected data_quality_report ids" do
          expect(Set.new(run.data_quality_report_ids)).to eq(Set.new([data_quality_report_1, data_quality_report_2, data_quality_report_3].map(&:id)))
        end
      end

      describe "data_quality_reports_successfully_completed?" do
        it "should return true when all data quality report steps are successfully_completed" do
          create(:run_step_log, run: run, completed: true, step_name: 'data_quality_reports', step_id: data_quality_report_1.id)
          create(:run_step_log, run: run, completed: true, step_name: 'data_quality_reports', step_id: data_quality_report_2.id)
          create(:run_step_log, run: run, completed: true, step_name: 'data_quality_reports', step_id: data_quality_report_3.id)
          expect(run.data_quality_reports_successfully_completed?).to eq(true)
        end

        it "should return false when one of the data quality reports has an error" do
          create(:run_step_log, run: run, completed: true, step_name: 'data_quality_reports', step_id: data_quality_report_1.id)
          create(:run_step_log, run: run, step_errors: { too_bad: :dude }, step_name: 'data_quality_reports', step_id: data_quality_report_2.id)
          create(:run_step_log, run: run, completed: true, step_name: 'data_quality_reports', step_id: data_quality_report_3.id)
          expect(run.data_quality_reports_successfully_completed?).to eq(false)
        end

        it "should return false when one of the data quality reports has not yet completed" do
          create(:run_step_log, run: run, completed: true, step_name: 'data_quality_reports', step_id: data_quality_report_1.id)
          create(:run_step_log, run: run, completed: false, step_name: 'data_quality_reports', step_id: data_quality_report_2.id)
          create(:run_step_log, run: run, completed: true, step_name: 'data_quality_reports', step_id: data_quality_report_3.id)
          expect(run.data_quality_reports_successfully_completed?).to eq(false)
        end
      end

    end

    describe "#with_run_step_log_tracking and #ordered_step_logs" do
      it "should create a new RunStepLog for the Run and flag it as successful when no exception is raised" do
        run = create(:run)

        expect(run.with_run_step_log_tracking(step_name: 'create_schema') { nil }).to eq(true)

        statuses = run.ordered_step_logs
        expect(statuses.size).to eq(1)
        status = statuses.first
        expect(status.run).to eq(run) # duh
        expect(status.step_name).to eq('create_schema')
        expect(status.successful?).to eq(true)
        expect(status.completed?).to eq(true)
        expect(status.running?).to eq(false)
        expect(status.step_errors).to eq(nil)
      end

      it "should create a new RunStepLog for the Run and flag it as unsuccessful and preserve the erring IDs in the error" do
        run = create(:run)
        error_h = { 'ids_failing_validation' => %w(1 5 111) }

        expect(run.with_run_step_log_tracking(step_name: 'create_schema') { error_h }).to eq(false)

        statuses = run.ordered_step_logs
        expect(statuses.size).to eq(1)
        status = statuses.first
        expect(status.run).to eq(run) # duh
        expect(status.step_name).to eq('create_schema')
        expect(status.successful?).to eq(false)
        expect(status.completed?).to eq(false)
        expect(status.running?).to eq(false)
        expect(status.step_errors).to eq(error_h)
      end

      it "should create a new RunStepLog for the Run and add exception details when an exception is raised" do
        run = create(:run)

        error_text = "Boom!"

        expect(run.with_run_step_log_tracking(step_name: 'create_schema') { raise error_text }).to eq(false)

        statuses = run.ordered_step_logs
        expect(statuses.size).to eq(1)
        status = statuses.first
        expect(status.run).to eq(run) # duh
        expect(status.step_name).to eq('create_schema')
        expect(status.successful?).to eq(false)
        expect(status.completed?).to eq(false)
        expect(status.running?).to eq(false)
        errors = status.step_errors
        expect(errors).to_not be_empty
        expect(errors['class_and_message']).to eq("#<RuntimeError: Boom!>")
        expect(errors['backtrace']).to_not be_empty
      end
    end

    describe "#create_schema" do

      let!(:run) { create(:run) }

      it "should create all the specified tables" do
        run.create_schema
        expect(run.schema_exists?).to eq(true)
      end
    end

  end
end
