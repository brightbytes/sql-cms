# == Schema Information
#
# Table name: transforms
#
#  id           :integer          not null, primary key
#  name         :string           not null
#  runner       :string           default("Sql"), not null
#  workflow_id  :integer          not null
#  sql          :text             not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  params       :jsonb
#  s3_file_name :string
#  enabled      :boolean          default(TRUE), not null
#
# Indexes
#
#  index_transforms_on_lowercase_name_and_workflow_id  (lower((name)::text), workflow_id) UNIQUE
#  index_transforms_on_workflow_id                     (workflow_id)
#
# Foreign Keys
#
#  fk_rails_...  (workflow_id => workflows.id)
#

describe Transform do

  describe 'versioned by PaperTrail' do
    it { is_expected.to be_versioned }
  end

  describe "validations" do
    [:name, :runner, :sql, :workflow].each do |att|
      it { should validate_presence_of(att) }
    end

    context "with a transform already extant" do
      let!(:subject) { create(:transform) }
      it { should validate_uniqueness_of(:name).scoped_to(:workflow_id).case_insensitive }
    end

    it { should validate_inclusion_of(:runner).in_array(RunnerFactory::RUNNERS) }

    it "should require the presence of the s3_file_name for all RunnerFactory::S3_FILE_RUNNERS" do
      RunnerFactory::S3_FILE_RUNNERS.each do |runner|
        t = build(:transform, runner: runner, params: { table_name: 'whatever' })
        expect(t).to_not be_valid
        expect(t.errors[:s3_file_name]).to_not eq(nil)
        expect(t.errors[:supplied_s3_url]).to_not eq(nil)
        t.s3_file_name = 'barfoo.csv'
        expect(t).to be_valid
      end
    end

    # FIXME - We may reuse this in Workflow ... but not right now
    # it "should add an error if a supplied_s3_url's region or bucket differ from the workflow's region or bucket, respectively" do
    #   transform = build(:copy_from_transform, s3_file_path: nil, s3_file_name: nil, specify_s3_file_by: 'url')
    #   transform.supplied_s3_url = "https://s3-#{transform.workflow.s3_region_name}.amazonaws.com/#{transform.workflow.s3_bucket_name}/ca_some_sis/some_data_source/shoobie.tsv"
    #   expect(transform.valid?).to eq(true)

    #   transform = build(:copy_from_transform, s3_file_path: nil, s3_file_name: nil, specify_s3_file_by: 'url')
    #   transform.supplied_s3_url = "https://s3-#{transform.workflow.s3_region_name}-junk.amazonaws.com/#{transform.workflow.s3_bucket_name}/ca_some_sis/some_data_source/shoobie.tsv"
    #   expect(transform.valid?).to_not eq(true)

    #   transform = build(:copy_from_transform, s3_file_path: nil, s3_file_name: nil, specify_s3_file_by: 'url')
    #   transform.supplied_s3_url = "https://s3-#{transform.workflow.s3_region_name}.amazonaws.com/#{transform.workflow.s3_bucket_name}-junk/ca_some_sis/some_data_source/shoobie.tsv"
    #   expect(transform.valid?).to_not eq(true)
    # end

  end

  describe "callbacks" do

    context "before_validation" do
      # FIXME - We may reuse this in Workflow ... but not right now
      # it "should parse a valid supplied s3-resource URL if possible" do
      #   transform = build(:copy_from_transform, s3_file_path: nil, s3_file_name: nil, specify_s3_file_by: 'url')
      #   transform.supplied_s3_url = "https://s3-#{transform.workflow.s3_region_name}.amazonaws.com/#{transform.workflow.s3_bucket_name}/ca_some_sis/some_data_source/shoobie.tsv"
      #   expect(transform.valid?).to eq(true)
      #   expect(transform.s3_file_path).to eq('ca_some_sis/some_data_source')
      #   expect(transform.s3_file_name).to eq('shoobie.tsv')

      #   transform = build(:copy_from_transform, s3_file_path: nil, s3_file_name: nil, specify_s3_file_by: 'url')
      #   transform.supplied_s3_url = "https://s3-#{transform.workflow.s3_region_name}.amazonaws.com/#{transform.workflow.s3_bucket_name}/shoobie.tsv"
      #   expect(transform.valid?).to eq(true)
      #   expect(transform.s3_file_path).to eq(nil)
      #   expect(transform.s3_file_name).to eq('shoobie.tsv')

      #   # This is a validation test, but it's here just because it feels right
      #   transform = build(:copy_from_transform, s3_file_path: nil, s3_file_name: nil, specify_s3_file_by: 'url')
      #   transform.supplied_s3_url = "https://s3-us-west-2.amazonaws.com/some-bucket"
      #   expect(transform.valid?).to eq(false)
      # end

      it "should clear s3 attribute for Transform Runners that don't use S3" do
        transform = build(:transform, s3_file_name: 'dude')
        expect(transform).to be_valid
        expect(transform.s3_file_name).to eq(nil)
      end

      it "should add the sql-dynamically-generated message for import Transforms when no sql is provided" do
        RunnerFactory::IMPORT_S3_FILE_RUNNERS.each do |runner|
          transform = build(:transform, runner: runner, sql: "")
          transform.valid?
          expect(transform.sql).to eq(Transform::SQL_DYNAMICALLY_GENERATED_MSG)
        end
      end

      it "should nuke all transform dependencies when changing a transform's workflow" do
        new_workflow = create(:workflow)

        td = create(:transform_dependency)
        t = td.prerequisite_transform
        t.workflow = new_workflow
        expect(t.save).to eq(true)
        expect(TransformDependency.find_by(id: td.id)).to eq(nil)

        td = create(:transform_dependency)
        t = td.postrequisite_transform
        t.workflow = new_workflow
        expect(t.save).to eq(true)
        expect(TransformDependency.find_by(id: td.id)).to eq(nil)
      end

    end

  end

  describe "associations" do
    it { should belong_to(:workflow) }

    it { should have_many(:prerequisite_dependencies) }
    it { should have_many(:prerequisite_transforms) }
    it { should have_many(:postrequisite_dependencies) }
    it { should have_many(:postrequisite_transforms) }

    it { should have_many(:transform_validations) }
    it { should have_many(:validations) }
  end

  describe "instance methods" do

    context "#enabled" do
      it "should prevent the Transform from being executed" do
        transform = create(:transform, enabled: false)
        workflow_configuration = create(:workflow_configuration, workflow: transform.workflow)
        run = workflow_configuration.runs.create!(creator: create(:user), execution_plan: workflow_configuration.serialize_and_symbolize)
        Sidekiq::Testing.inline! do
          TransformJob.perform_later(run_id: run.id, step_index: 0, step_id: transform.id)
          run.reload
          logs = run.run_step_logs.where(step_type: 'transform').to_a
          log = logs.first
          expect(log.step_exceptions).to eq(nil)
          expect(log.step_validation_failures).to eq(nil)
          expect(log.successful?).to eq(true)
          expect(log.step_result).to eq({ 'transform_disabled' => true })
        end
      end
    end

    context "#params" do
      let!(:subject) { build(:transform) }
      include_examples 'yaml helper methods'
    end

    context "runner-type methods" do
      it "should have an #importing? method" do
        RunnerFactory::IMPORT_S3_FILE_RUNNERS.each do |runner|
          expect(build(:transform, runner: runner).importing?).to eq(true)
        end
        (RunnerFactory::RUNNERS - RunnerFactory::IMPORT_S3_FILE_RUNNERS).each do |runner|
          expect(build(:transform, runner: runner).importing?).to eq(false)
        end
      end
      it "should have an #exporting? method" do
        RunnerFactory::EXPORT_S3_FILE_RUNNERS.each do |runner|
          expect(build(:transform, runner: runner).exporting?).to eq(true)
        end
        (RunnerFactory::RUNNERS - RunnerFactory::EXPORT_S3_FILE_RUNNERS).each do |runner|
          expect(build(:transform, runner: runner).exporting?).to eq(false)
        end
      end
      it "should have an #s3_file_required? method" do
        RunnerFactory::S3_FILE_RUNNERS.each do |runner|
          expect(build(:transform, runner: runner).s3_file_required?).to eq(true)
        end
        (RunnerFactory::RUNNERS - RunnerFactory::S3_FILE_RUNNERS).each do |runner|
          expect(build(:transform, runner: runner).s3_file_required?).to eq(false)
        end
      end
      it "should have an #auto_load? method" do
        expect(build(:transform, runner: 'AutoLoad').auto_load?).to eq(true)
        (RunnerFactory::RUNNERS - ['AutoLoad']).each do |runner|
          expect(build(:transform, runner: runner).auto_load?).to eq(false)
        end
      end
    end

    context "S3 Import File method" do
      it "should return a correctly-initialized S3 Import File" do
        w = create(:workflow)
        wc = create(:workflow_configuration, workflow: w, s3_file_path: 'some/file/path')
        t = create(:transform, workflow: w, runner: 'CopyFrom', s3_file_name: 'foobar.csv', params: { table_name: 'whatever' })
        file = t.s3_import_file(wc)
        expect(file.s3_region_name).to eq(wc.s3_region_name)
        expect(file.s3_bucket_name).to eq(wc.s3_bucket_name)
        expect(file.s3_file_path).to eq(wc.s3_file_path)
        expect(file.s3_file_name).to eq(t.s3_file_name)
      end
    end

    context "#available_prerequisite_transforms" do

      include_examples 'cheesey transform dependency graph'

      it "should return the correct list of prerequisites in all cases" do
        expect(Set.new(Transform.new(workflow: workflow).available_prerequisite_transforms)).to eq(Set.new([most_dependent_transform, independent_transform, first_child_transform, less_dependent_transform, another_less_dependent_transform, least_dependent_transform]))
        expect(Set.new(most_dependent_transform.available_prerequisite_transforms)).to eq(Set.new([independent_transform, first_child_transform, less_dependent_transform, another_less_dependent_transform, least_dependent_transform]))
        expect(Set.new(first_child_transform.available_prerequisite_transforms)).to eq(Set.new([independent_transform, less_dependent_transform, another_less_dependent_transform, least_dependent_transform]))
        expect(Set.new(less_dependent_transform.available_prerequisite_transforms)).to eq(Set.new([independent_transform, first_child_transform, another_less_dependent_transform, least_dependent_transform]))
        expect(Set.new(another_less_dependent_transform.available_prerequisite_transforms)).to eq(Set.new([independent_transform, first_child_transform, less_dependent_transform, least_dependent_transform]))
        expect(Set.new(least_dependent_transform.available_prerequisite_transforms)).to eq(Set.new([independent_transform, first_child_transform]))
        expect(Set.new(independent_transform.available_prerequisite_transforms)).to eq(Set.new([most_dependent_transform, first_child_transform, less_dependent_transform, another_less_dependent_transform, least_dependent_transform]))
      end

    end

  end
end
