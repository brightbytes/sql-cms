# frozen_string_literal: true
# == Schema Information
#
# Table name: public.transform_validations
#
#  id            :integer          not null, primary key
#  transform_id  :integer          not null
#  validation_id :integer          not null
#  params        :jsonb            not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_transform_validations_on_validation_id  (validation_id)
#
# Foreign Keys
#
#  fk_rails_...  (transform_id => transforms.id)
#  fk_rails_...  (validation_id => validations.id)
#

describe TransformValidation do

  describe 'versioned by PaperTrail' do
    it { is_expected.to be_versioned }
  end

  describe "validations" do
    [:transform, :params, :validation].each do |att|
      it { should validate_presence_of(att) }
    end

    context "with a transform_validation already extant, and having a data_file" do
      let!(:subject) { create(:transform_validation) }
    end

  end

  describe "associations" do
    it { should belong_to(:transform) }
    it { should belong_to(:validation) }
  end

  describe "instance methods" do
    # describe "#run" do
    #   before { User.seed }

    #   context "presence validation" do

    #     let!(:workflow) { create(:workflow, ddl: "CREATE TABLE test_table (id serial primary key, test_column character varying)") }

    #     let!(:transform) { create(:initial_dimension_map_transform, dml: "INSERT INTO test_table (id, test_column) VALUES (1, 'foo'), (2, NULL), (3, 'bar'), (4, ''), (5, ' '), (6, '  blah  ')") }

    #     let!(:pipeline_transform) { create(:pipeline_transform, pipeline: pipeline, transform: transform) }

    #     let!(:transform_validation) { create(:transform_validation, :presence, transform: transform, params: { table_name: :test_table, column_name: :test_column }) }

    #     let!(:run) { create(:run, pipeline: pipeline).tap(&:create_schema_and_tables!) }

    #     it "should correctly identify which rows have values that aren't present" do
    #       statuses = run.ordered_statuses
    #       expect(statuses.size).to eq(1)
    #       status = statuses.first
    #       expect(status.step).to eq(pipeline)
    #       expect(status.step_successful).to be true
    #       expect(status.step_errors).to be_empty

    #       expect(pipeline_transform.run(run)).to eq(false)

    #       statuses = run.ordered_statuses
    #       expect(statuses.size).to eq(3)
    #       status = statuses.last
    #       expect(status.step).to eq(transform_validation)
    #       expect(status.step_successful).to be false
    #       expect(status.step_errors).to eq('ids_failing_validation' => %w(2 4 5))
    #     end
    #   end

    #   context "non-null validation" do

    #     let!(:pipeline) { create(:pipeline, ddl: "CREATE TABLE test_table (id serial primary key, test_column integer)") }

    #     let!(:transform) { create(:initial_dimension_map_transform, dml: "INSERT INTO test_table (id, test_column) VALUES (1, NULL), (2, 1), (3, 2), (4, NULL), (5, 0)") }

    #     let!(:pipeline_transform) { create(:pipeline_transform, pipeline: pipeline, transform: transform) }

    #     let!(:transform_validation) { create(:transform_validation, :not_null, transform: transform, params: { table_name: :test_table, column_name: :test_column }) }

    #     let!(:run) { create(:run, pipeline: pipeline).tap(&:create_schema_and_tables!) }

    #     it "should correctly identify which rows have values that are null" do
    #       statuses = run.ordered_statuses
    #       expect(statuses.size).to eq(1)
    #       status = statuses.first
    #       expect(status.step).to eq(pipeline)
    #       expect(status.step_successful).to be true
    #       expect(status.step_errors).to be_empty

    #       expect(pipeline_transform.run(run)).to eq(false)

    #       statuses = run.ordered_statuses
    #       expect(statuses.size).to eq(3)
    #       status = statuses.last
    #       expect(status.step).to eq(transform_validation)
    #       expect(status.step_successful).to be false
    #       expect(status.step_errors).to eq('ids_failing_validation' => %w(1 4))
    #     end
    #   end

    #   context "uniqueness validation" do

    #     let!(:pipeline) { create(:pipeline, ddl: "CREATE TABLE test_table (id serial primary key, test_column integer)") }

    #     let!(:transform) { create(:initial_dimension_map_transform, dml: "INSERT INTO test_table (id, test_column) VALUES (1, NULL), (2, 1), (3, 1), (4, 2), (5, 3), (6, NULL), (7, 2)") }

    #     let!(:pipeline_transform) { create(:pipeline_transform, pipeline: pipeline, transform: transform) }

    #     let!(:transform_validation) { create(:transform_validation, :uniqueness, transform: transform, params: { table_name: :test_table, column_name: :test_column }) }

    #     let!(:run) { create(:run, pipeline: pipeline).tap(&:create_schema_and_tables!) }

    #     it "should correctly identify which rows have values that are non-unique" do
    #       statuses = run.ordered_statuses
    #       expect(statuses.size).to eq(1)
    #       status = statuses.first
    #       expect(status.step).to eq(pipeline)
    #       expect(status.step_successful).to be true
    #       expect(status.step_errors).to be_empty

    #       expect(pipeline_transform.run(run)).to eq(false)

    #       statuses = run.ordered_statuses
    #       expect(statuses.size).to eq(3)
    #       status = statuses.last
    #       expect(status.step).to eq(transform_validation)
    #       expect(status.step_successful).to be false
    #       expect(status.step_errors).to eq('ids_failing_validation' => %w(2 3 4 7))
    #     end
    #   end

    #   context "greater than 0 validation" do

    #     let!(:pipeline) { create(:pipeline, ddl: "CREATE TABLE test_table (id serial primary key, test_column integer)") }

    #     let!(:transform) { create(:initial_dimension_map_transform, dml: "INSERT INTO test_table (id, test_column) VALUES (1, NULL), (2, 1), (3, 1), (4, 0), (5, -1), (6, NULL), (7, 2)") }

    #     let!(:pipeline_transform) { create(:pipeline_transform, pipeline: pipeline, transform: transform) }

    #     let!(:transform_validation) { create(:transform_validation, :greater_than_zero_validation, transform: transform, params: { table_name: :test_table, column_name: :test_column }) }

    #     let!(:run) { create(:run, pipeline: pipeline).tap(&:create_schema_and_tables!) }

    #     it "should correctly identify which rows have values that are less than or equal to 0" do
    #       statuses = run.ordered_statuses
    #       expect(statuses.size).to eq(1)
    #       status = statuses.first
    #       expect(status.step).to eq(pipeline)
    #       expect(status.step_successful).to be true
    #       expect(status.step_errors).to be_empty

    #       expect(pipeline_transform.run(run)).to eq(false)

    #       statuses = run.ordered_statuses
    #       expect(statuses.size).to eq(3)
    #       status = statuses.last
    #       expect(status.step).to eq(transform_validation)
    #       expect(status.step_successful).to be false
    #       expect(status.step_errors).to eq('ids_failing_validation' => %w(4 5))
    #     end
    #   end

    #   context "greater than or equal to 0 validation" do

    #     let!(:pipeline) { create(:pipeline, ddl: "CREATE TABLE test_table (id serial primary key, test_column integer)") }

    #     let!(:transform) { create(:initial_dimension_map_transform, dml: "INSERT INTO test_table (id, test_column) VALUES (1, NULL), (2, -5), (3, 1), (4, 0), (5, -1), (6, NULL), (7, 2)") }

    #     let!(:pipeline_transform) { create(:pipeline_transform, pipeline: pipeline, transform: transform) }

    #     let!(:transform_validation) { create(:transform_validation, :greater_than_or_equal_to_zero_validation, transform: transform, params: { table_name: :test_table, column_name: :test_column }) }

    #     let!(:run) { create(:run, pipeline: pipeline).tap(&:create_schema_and_tables!) }

    #     it "should correctly identify which rows have values that are less than 0" do
    #       statuses = run.ordered_statuses
    #       expect(statuses.size).to eq(1)
    #       status = statuses.first
    #       expect(status.step).to eq(pipeline)
    #       expect(status.step_successful).to be true
    #       expect(status.step_errors).to be_empty

    #       expect(pipeline_transform.run(run)).to eq(false)

    #       statuses = run.ordered_statuses
    #       expect(statuses.size).to eq(3)
    #       status = statuses.last
    #       expect(status.step).to eq(transform_validation)
    #       expect(status.step_successful).to be false
    #       expect(status.step_errors).to eq('ids_failing_validation' => %w(2 5))
    #     end
    #   end

    #   context "FK validation" do

    #     let!(:pipeline) { create(:pipeline, ddl: "CREATE TABLE test_mappings (id serial primary key, whatever integer); CREATE TABLE test_fact_table (id serial primary key, test_mapping_id integer)") }

    #     let!(:transform) { create(:initial_dimension_map_transform, dml: "INSERT INTO test_mappings (id, whatever) VALUES (1, NULL), (2, 1), (3, 1), (6, NULL), (7, 2); INSERT INTO test_fact_table (id, test_mapping_id) VALUES (1, 1), (2, 2), (3, 3), (4, 4), (5, 5), (6, 6)") }

    #     let!(:pipeline_transform) { create(:pipeline_transform, pipeline: pipeline, transform: transform) }

    #     let!(:transform_validation) { create(:transform_validation, :fk, transform: transform, params: { fk_table_name: :test_fact_table, fk_column_name: :test_mapping_id, pk_table_name: :test_mappings, pk_column_name: :id }) }

    #     let!(:run) { create(:run, pipeline: pipeline).tap(&:create_schema_and_tables!) }

    #     it "should correctly identify which rows have values that violate an (in-app) FK constraint" do
    #       statuses = run.ordered_statuses
    #       expect(statuses.size).to eq(1)
    #       status = statuses.first
    #       expect(status.step).to eq(pipeline)
    #       expect(status.step_successful).to be true
    #       expect(status.step_errors).to be_empty

    #       expect(pipeline_transform.run(run)).to eq(false)

    #       statuses = run.ordered_statuses
    #       expect(statuses.size).to eq(3)
    #       status = statuses.last
    #       expect(status.step).to eq(transform_validation)
    #       expect(status.step_successful).to be false
    #       expect(status.step_errors).to eq('ids_failing_validation' => %w(4 5))
    #     end
    #   end

    #   context "no-overlap validation" do

    #     let!(:pipeline) { create(:pipeline, ddl: "CREATE TABLE test_table (id serial primary key, low_val integer, high_val integer)") }

    #     let!(:transform) { create(:initial_dimension_map_transform, dml: "INSERT INTO test_table (id, low_val, high_val) VALUES (1, -10, 1), (2, 2, 5), (3, 4, 6), (4, 8, 30), (5, 30, 35), (6, 40, 40), (7, 40, 45), (8, 50, 100)") }

    #     let!(:pipeline_transform) { create(:pipeline_transform, pipeline: pipeline, transform: transform) }

    #     let!(:transform_validation) { create(:transform_validation, :no_overlap, transform: transform, params: { table_name: :test_table, low_column_name: :low_val, high_column_name: :high_val }) }

    #     let!(:run) { create(:run, pipeline: pipeline).tap(&:create_schema_and_tables!) }

    #     it "should correctly identify which rows have values that are null" do
    #       statuses = run.ordered_statuses
    #       expect(statuses.size).to eq(1)
    #       status = statuses.first
    #       expect(status.step).to eq(pipeline)
    #       expect(status.step_successful).to be true
    #       expect(status.step_errors).to be_empty

    #       expect(pipeline_transform.run(run)).to eq(false)

    #       statuses = run.ordered_statuses
    #       expect(statuses.size).to eq(3)
    #       status = statuses.last
    #       expect(status.step).to eq(transform_validation)
    #       expect(status.step_successful).to be false
    #       expect(status.step_errors).to eq('ids_failing_validation' => %w(2 3 4 5 6 7))
    #     end
    #   end

    # end
  end
end
