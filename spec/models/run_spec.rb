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

    # describe "#with_run_status_tracking and #ordered_statuses" do
    #   it "should create a new RunStatus for the Run and flag it as successful when no exception is raised" do
    #     run = create(:run)

    #     expect(run.with_run_status_tracking(run.pipeline) { nil }).to eq(true)

    #     statuses = run.ordered_statuses
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

    #     expect(run.with_run_status_tracking(run.pipeline) { error_h }).to eq(false)

    #     statuses = run.ordered_statuses
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

    #     expect(run.with_run_status_tracking(run.pipeline) { raise error_text }).to eq(false)

    #     statuses = run.ordered_statuses
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
