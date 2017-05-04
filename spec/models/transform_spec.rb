# == Schema Information
#
# Table name: public.transforms
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
#
# Indexes
#
#  index_transforms_on_lowercase_name  (lower((name)::text)) UNIQUE
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
      it { should validate_uniqueness_of(:name).case_insensitive }
    end

    it { should validate_inclusion_of(:runner).in_array(RunnerFactory::RUNNERS) }

    it "should require the presence of the s3_file_name for all RunnerFactory::S3_FILE_RUNNERS" do
      RunnerFactory::S3_FILE_RUNNERS.each do |runner|
        t = build(:transform, runner: runner)
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

      it "should generate the default TSV SQL if no #sql is present and the runner is 'CopyFrom' and the import file is a TSV" do
        transform = build(:copy_from_transform, sql: nil, s3_file_name: 'shoobie.tsv')
        expect(transform.valid?).to eq(true)
        expect(transform.sql).to eq(Transform::DEFAULT_TSV_SQL)
      end

      it "should generate the default CSV SQL if no #sql is present and the runner is 'CopyFrom' and the import file is a CSV" do
        transform = build(:copy_from_transform, sql: nil, s3_file_name: 'shoobie.csv')
        expect(transform.valid?).to eq(true)
        expect(transform.sql).to eq(Transform::DEFAULT_CSV_SQL)
      end
    end

  end

  describe "associations" do
    it { should belong_to(:workflow) }
    it { should have_one(:customer) }

    it { should have_many(:prerequisite_dependencies) }
    it { should have_many(:prerequisite_transforms) }
    it { should have_many(:postrequisite_dependencies) }
    it { should have_many(:postrequisite_transforms) }

    it { should have_many(:transform_validations) }
    it { should have_many(:validations) }
  end

  describe "instance methods" do

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

    context "Methods returning an S3File" do

    end

    context "#available_prerequisite_transforms" do

      include_examples 'cheesey dependency graph'

      it "should return the correct list of prerequisites in all cases" do
        expect(Set.new(most_dependent_transform.available_prerequisite_transforms)).to eq(Set.new([independent_transform, first_child_transform, less_dependent_transform, another_less_dependent_transform, least_dependent_transform]))
        expect(Set.new(first_child_transform.available_prerequisite_transforms)).to eq(Set.new([independent_transform, less_dependent_transform, another_less_dependent_transform, least_dependent_transform]))
        expect(Set.new(less_dependent_transform.available_prerequisite_transforms)).to eq(Set.new([independent_transform, first_child_transform, another_less_dependent_transform, least_dependent_transform]))
        expect(Set.new(another_less_dependent_transform.available_prerequisite_transforms)).to eq(Set.new([independent_transform, first_child_transform, less_dependent_transform, least_dependent_transform]))
        expect(Set.new(least_dependent_transform.available_prerequisite_transforms)).to eq(Set.new([independent_transform, first_child_transform]))
        expect(Set.new(independent_transform.available_prerequisite_transforms)).to eq(Set.new([most_dependent_transform, first_child_transform, less_dependent_transform, another_less_dependent_transform, least_dependent_transform]))
      end

    end

    # context "#available_unused_prerequisite_transforms" do

    #   include_examples 'cheesey dependency graph'

    #   it "should return the correct list of prerequisites in all cases" do
    #     expect(most_dependent_transform.available_unused_prerequisite_transforms).to eq([independent_transform])
    #     expect(Set.new(first_child_transform.available_unused_prerequisite_transforms)).to eq(Set.new([independent_transform, less_dependent_transform, another_less_dependent_transform, least_dependent_transform]))
    #     expect(Set.new(less_dependent_transform.available_unused_prerequisite_transforms)).to eq(Set.new([independent_transform, first_child_transform, another_less_dependent_transform]))
    #     expect(Set.new(another_less_dependent_transform.available_unused_prerequisite_transforms)).to eq(Set.new([independent_transform, first_child_transform, less_dependent_transform]))
    #     expect(Set.new(least_dependent_transform.available_unused_prerequisite_transforms)).to eq(Set.new([independent_transform, first_child_transform]))
    #     expect(Set.new(independent_transform.available_unused_prerequisite_transforms)).to eq(Set.new([most_dependent_transform, first_child_transform, less_dependent_transform, another_less_dependent_transform, least_dependent_transform]))
    #   end

    # end

  end
end
