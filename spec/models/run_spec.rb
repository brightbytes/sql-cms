# == Schema Information
#
# Table name: public.runs
#
#  id                        :integer          not null, primary key
#  creator_id                :integer          not null
#  execution_plan            :jsonb            not null
#  status                    :string           default("unstarted"), not null
#  notification_status       :string           default("unsent"), not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  schema_name               :string
#  workflow_configuration_id :integer          not null
#  immutable                 :boolean          default(FALSE), not null
#
# Indexes
#
#  index_runs_on_creator_id                 (creator_id)
#  index_runs_on_workflow_configuration_id  (workflow_configuration_id)
#
# Foreign Keys
#
#  fk_rails_...  (creator_id => users.id)
#  fk_rails_...  (workflow_configuration_id => workflow_configurations.id)
#

describe Run do

  # Having this in `spec_helper.rb` breaks other tests in this suite.  However, it's necessary here for defining `ApplicationJob.queue_adapter`'s enqueued_jobs method.
  # ... and that's necessary in turn because Sidekiq's #jobs method is unavailable with ActiveJob.  Fun!
  include ActiveJob::TestHelper

  describe 'versioned by PaperTrail' do
    it { is_expected.to be_versioned }
  end

  describe "validations" do
    [:workflow_configuration, :creator, :execution_plan, :status, :notification_status].each do |att|
      it { should validate_presence_of(att) }
    end

    it { should validate_inclusion_of(:notification_status).in_array(described_class::NOTIFICATION_STATUSES) }
  end

  describe "associations" do
    it { should have_many(:run_step_logs) }
    it { should belong_to(:creator) }
    it { should belong_to(:workflow_configuration) }
  end

  describe "callbacks" do

    it "should be immutable when flagged as such" do
      run = create(:run)
      expect(run.immutable?).to eq(false)
      expect(run.read_only?).to eq(false)
      run.update_attribute(:immutable, true)
      expect { run.destroy }.to raise_error("You may not destroy an immutable Run")
      expect { run.delete }.to raise_error("You may not bypass callbacks to delete a Class.")
      expect { run.update_attribute(:status, "/* Blah */") }.to raise_error("You may not update an immutable Run")
      expect { run.update_attributes(status: "/* Blah */") }.to raise_error("You may not update an immutable Run")
      expect { run.update_column(:status, "/* Blah */") }.to raise_error("You may not bypass callbacks to update a Class.")
    end

    context "after_create" do
      it "should set the schema_name" do
        run = build(:run)
        expect(run.schema_name).to be_nil
        expect(run.save).to eq(true)
        expect(run.schema_name).to eq("#{run.workflow_configuration}_run_#{run.id}")
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
        expect(run.schema_name).to eq("#{run.workflow_configuration}_run_#{run.id}")
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

      it "should return true when any step log has an exception" do
        2.times { create(:run_step_log, run: run) }
        create(:run_step_log, run: run, successful: true)
        expect(run.failed?).to eq(false)
        create(:run_step_log, run: run, step_exceptions: { whatever: :dude })
        expect(run.failed?).to eq(true)
      end

      it "should return true when any step log has an validation failure" do
        2.times { create(:run_step_log, run: run) }
        create(:run_step_log, run: run, successful: true)
        expect(run.failed?).to eq(false)
        create(:run_step_log, run: run, step_validation_failures: { whatever: :dude })
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

      describe "transform_group_successful?" do

        it "should return true when all transform group steps are successful" do
          create(:run_step_log, run: run, successful: true, step_type: 'transform', step_index: 0, step_id: independent_transform.id)
          create(:run_step_log, run: run, successful: true, step_type: 'transform', step_index: 0, step_id: least_dependent_transform.id)
          create(:run_step_log, run: run, successful: true, step_type: 'transform', step_index: 0, step_id: first_child_transform.id)
          expect(run.transform_group_successful?(0)).to eq(true)
        end

        it "should return false when one of the transforms has an exception" do
          create(:run_step_log, run: run, successful: true, step_type: 'transform', step_index: 0, step_id: independent_transform.id)
          create(:run_step_log, run: run, step_exceptions: { too_bad: :dude }, step_type: 'transform', step_index: 0, step_id: least_dependent_transform.id)
          create(:run_step_log, run: run, successful: true, step_type: 'transform', step_index: 0, step_id: first_child_transform.id)
          expect(run.transform_group_successful?(0)).to eq(false)
        end

        it "should return false when one of the transforms has an validation failure" do
          create(:run_step_log, run: run, successful: true, step_type: 'transform', step_index: 0, step_id: independent_transform.id)
          create(:run_step_log, run: run, step_validation_failures: { too_bad: :dude }, step_type: 'transform', step_index: 0, step_id: least_dependent_transform.id)
          create(:run_step_log, run: run, successful: true, step_type: 'transform', step_index: 0, step_id: first_child_transform.id)
          expect(run.transform_group_successful?(0)).to eq(false)
        end

        it "should return false when one of the transforms hasn't been successful" do
          create(:run_step_log, run: run, successful: true, step_type: 'transform', step_index: 0, step_id: independent_transform.id)
          create(:run_step_log, run: run, successful: false, step_type: 'transform', step_index: 0, step_id: least_dependent_transform.id)
          create(:run_step_log, run: run, successful: true, step_type: 'transform', step_index: 0, step_id: first_child_transform.id)
          expect(run.transform_group_successful?(0)).to eq(false)
        end

      end

      describe "#workflow_data_quality_reports" do
        it "should return the expected workflow_data_quality_reports hash" do
          expect(run.workflow_data_quality_reports).to eq(run.execution_plan[:workflow_data_quality_reports])
        end
      end

      describe "#workflow_data_quality_report_ids" do
        it "should return the expected workflow_data_quality_report ids" do
          expect(Set.new(run.workflow_data_quality_report_ids)).to eq(Set.new([workflow_data_quality_report_1, workflow_data_quality_report_2, workflow_data_quality_report_3].map(&:id)))
        end
      end

      describe "#workflow_data_quality_report_plan" do
        it "should return the expected workflow_data_quality_report hashes" do
          expect(run.workflow_data_quality_report_plan(workflow_data_quality_report_1.id)).to eq(ActiveModelSerializers::SerializableResource.new(workflow_data_quality_report_1).as_json)
          expect(run.workflow_data_quality_report_plan(workflow_data_quality_report_2.id)).to eq(ActiveModelSerializers::SerializableResource.new(workflow_data_quality_report_2).as_json)
          expect(run.workflow_data_quality_report_plan(workflow_data_quality_report_3.id)).to eq(ActiveModelSerializers::SerializableResource.new(workflow_data_quality_report_3).as_json)
          expect(run.workflow_data_quality_report_plan(123421234324)).to eq(nil)
        end
      end

      describe "workflow_data_quality_reports_successful?" do
        it "should return true when all data quality report steps are successful" do
          create(:run_step_log, run: run, successful: true, step_type: 'workflow_data_quality_report', step_id: workflow_data_quality_report_1.id)
          create(:run_step_log, run: run, successful: true, step_type: 'workflow_data_quality_report', step_id: workflow_data_quality_report_2.id)
          create(:run_step_log, run: run, successful: true, step_type: 'workflow_data_quality_report', step_id: workflow_data_quality_report_3.id)
          expect(run.workflow_data_quality_reports_successful?).to eq(true)
        end

        it "should return false when one of the data quality reports has an exception" do
          create(:run_step_log, run: run, successful: true, step_type: 'workflow_data_quality_report', step_id: workflow_data_quality_report_1.id)
          create(:run_step_log, run: run, step_exceptions: { too_bad: :dude }, step_type: 'workflow_data_quality_report', step_id: workflow_data_quality_report_2.id)
          create(:run_step_log, run: run, successful: true, step_type: 'workflow_data_quality_report', step_id: workflow_data_quality_report_3.id)
          expect(run.workflow_data_quality_reports_successful?).to eq(false)
        end

        it "should return false when one of the data quality reports has a validation failure" do
          create(:run_step_log, run: run, successful: true, step_type: 'workflow_data_quality_report', step_id: workflow_data_quality_report_1.id)
          create(:run_step_log, run: run, step_validation_failures: { too_bad: :dude }, step_type: 'workflow_data_quality_report', step_id: workflow_data_quality_report_2.id)
          create(:run_step_log, run: run, successful: true, step_type: 'workflow_data_quality_report', step_id: workflow_data_quality_report_3.id)
          expect(run.workflow_data_quality_reports_successful?).to eq(false)
        end

        it "should return false when one of the data quality reports has not yet successful" do
          create(:run_step_log, run: run, successful: true, step_type: 'workflow_data_quality_report', step_id: workflow_data_quality_report_1.id)
          create(:run_step_log, run: run, successful: false, step_type: 'workflow_data_quality_report', step_id: workflow_data_quality_report_2.id)
          create(:run_step_log, run: run, successful: true, step_type: 'workflow_data_quality_report', step_id: workflow_data_quality_report_3.id)
          expect(run.workflow_data_quality_reports_successful?).to eq(false)
        end
      end

    end

    describe "#with_run_step_log_tracking and #ordered_step_logs" do
      it "should create a new RunStepLog for the Run and flag it as successful when no exception is raised, and do so idempotently" do
        run = create(:run)

        2.times do
          expect(run.with_run_step_log_tracking(step_type: 'transform') { nil }).to eq(true)

          statuses = run.reload.ordered_step_logs
          expect(statuses.size).to eq(1)
          status = statuses.first
          expect(status.run).to eq(run) # duh
          expect(status.step_type).to eq('transform')
          expect(status.successful?).to eq(true)
          expect(status.failed?).to eq(false)
          expect(status.running_or_crashed?).to eq(false)
          expect(status.step_exceptions).to eq(nil)
          expect(status.step_validation_failures).to eq(nil)
        end
      end

      it "should create a new RunStepLog for the Run and flag it as unsuccessful and preserve the erring IDs in the error" do
        run = create(:run)
        failures_h = [{ 'ids_failing_validation' => %w(1 5 111) }]
        result_h = { step_validation_failures: failures_h }

        expect(run.with_run_step_log_tracking(step_type: 'transform') { result_h }).to eq(false)

        statuses = run.ordered_step_logs
        expect(statuses.size).to eq(1)
        status = statuses.first
        expect(status.run).to eq(run) # duh
        expect(status.step_type).to eq('transform')
        expect(status.successful?).to eq(false)
        expect(status.failed?).to eq(true)
        expect(status.running_or_crashed?).to eq(false)
        expect(status.step_exceptions).to eq(nil)
        expect(status.step_validation_failures).to eq(failures_h)
      end

      it "should create a new RunStepLog for the Run and add exception details when an exception is raised" do
        run = create(:run)
        error_text = "Boom!"

        expect(run.with_run_step_log_tracking(step_type: 'transform') { raise error_text }).to eq(false)

        statuses = run.ordered_step_logs
        expect(statuses.size).to eq(1)
        status = statuses.first
        expect(status.run).to eq(run) # duh
        expect(status.step_type).to eq('transform')
        expect(status.successful?).to eq(false)
        expect(status.failed?).to eq(true)
        expect(status.running_or_crashed?).to eq(false)
        errors = status.step_exceptions
        expect(errors).to_not be_empty
        expect(errors['class_and_message']).to eq("#<RuntimeError: Boom!>")
        expect(errors['message']).to eq("Boom!")
        expect(errors['backtrace']).to_not be_empty
        expect(status.step_validation_failures).to eq(nil)
      end

      it "should not create a RunStepLog when a deadlock exception is raised, and instead queue up a new TransformJob" do
        Sidekiq::Testing.fake!

        run = create(:run)
        error_text = "PG::TRDeadlockDetected - blah blah blither blah"

        expect(ApplicationJob.queue_adapter.enqueued_jobs.size).to eq(0)

        expect(run.with_run_step_log_tracking(step_type: 'transform') { raise error_text }).to eq(true)

        expect(run.ordered_step_logs.count).to eq(0)
        expect(ApplicationJob.queue_adapter.enqueued_jobs.size).to eq(1)
      end
    end

    describe "#create_schema" do

      let!(:run) { create(:run) }

      it "should create all the specified tables" do
        run.create_schema
        expect(run.schema_exists?).to eq(true)
      end
    end

    describe "#schema_dump" do
      let!(:run) { create(:run) }

      it "shouldn't puke - sorry, not going to validate it in any other way" do
        run.create_schema
        # quietly b/c shelling out - as this method does - doesn't allow pg_dump to see the schema, even though it exists, resulting in:
        #   "pg_dump: No matching schemas were found"
        expect { quietly { run.schema_dump } }.to_not raise_error
      end
    end

    describe "#duration_seconds" do
      let!(:run) { create(:run) }

      it "should return how long the Run took" do
        expect(run.duration_seconds).to be > 0.0
      end
    end

  end
end
