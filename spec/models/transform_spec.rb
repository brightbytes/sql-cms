# == Schema Information
#
# Table name: transforms
#
#  id                            :integer          not null, primary key
#  name                          :string           not null
#  runner                        :string           not null
#  workflow_id                   :integer          not null
#  params                    :jsonb            not null
#  sql                           :text             not null
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  transcompiled_source          :text
#  transcompiled_source_language :string
#  data_file_id                  :integer
#  copied_from_transform_id      :integer
#
# Indexes
#
#  index_transforms_on_copied_from_transform_id      (copied_from_transform_id)
#  index_transforms_on_data_file_id                  (data_file_id)
#  index_transforms_on_lowercase_name                (lower((name)::text)) UNIQUE
#  index_transforms_on_workflow_id_and_data_file_id  (workflow_id,data_file_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (copied_from_transform_id => transforms.id)
#  fk_rails_...  (data_file_id => data_files.id)
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
      # Doesn't work
      # it { should validate_uniqueness_of(:data_file).scoped_to(:workflow_id).allow_nil }
    end

    it "should validate that params is not null, but allow blank" do
      transform = create(:transform)
      transform.params = nil
      expect(transform.valid?).to be false

      transform.params = {}
      expect(transform.valid?).to be true
    end

    it { should validate_inclusion_of(:runner).in_array(described_class::RUNNERS) }
    it { should validate_inclusion_of(:transcompiled_source_language).in_array(described_class::TRANSCOMPILED_LANGUAGES).allow_nil }
  end

  describe "callbacks" do

  end

  describe "associations" do
    it { should belong_to(:workflow) }
    it { should have_one(:customer) }
    it { should belong_to(:data_file) }

    it { should belong_to(:copied_from_transform) }
    it { should have_many(:copied_to_transforms) }

    it { should have_many(:prerequisite_dependencies) }
    it { should have_many(:prerequisite_transforms) }
    it { should have_many(:postrequisite_dependencies) }
    it { should have_many(:postrequisite_transforms) }

    it { should have_many(:transform_validations) }
    it { should have_many(:validations) }
  end

  describe "instance methods" do

    context "#available_prerequisite_transforms && #available_unused_prerequisite_transforms" do
      let!(:workflow) { create(:workflow) }

      let!(:most_dependent_transform) { create(:transform, workflow: workflow) }
      let!(:first_child_transform) { create(:transform, workflow: workflow) }
      let!(:dependency_1) { create(:transform_dependency, prerequisite_transform: first_child_transform, postrequisite_transform: most_dependent_transform) }

      let!(:less_dependent_transform) { create(:transform, workflow: workflow) }
      let!(:dependency_2) { create(:transform_dependency, prerequisite_transform: less_dependent_transform, postrequisite_transform: most_dependent_transform) }

      let!(:another_less_dependent_transform) { create(:transform, workflow: workflow) }
      let!(:dependency_3) { create(:transform_dependency, prerequisite_transform: another_less_dependent_transform, postrequisite_transform: most_dependent_transform) }

      let!(:least_dependent_transform) { create(:transform, workflow: workflow) }
      let!(:dependency_4) { create(:transform_dependency, prerequisite_transform: least_dependent_transform, postrequisite_transform: less_dependent_transform) }

      let!(:dependency_5) { create(:transform_dependency, prerequisite_transform: least_dependent_transform, postrequisite_transform: another_less_dependent_transform) }

      let!(:independent_transform) { create(:transform, workflow: workflow) }

      let!(:another_workflow_transform) { create(:transform) }

      it "should return the correct list of prerequisites in all cases" do
        expect(most_dependent_transform.available_unused_prerequisite_transforms).to eq([independent_transform])
        expect(Set.new(first_child_transform.available_unused_prerequisite_transforms)).to eq(Set.new([independent_transform, less_dependent_transform, another_less_dependent_transform, least_dependent_transform]))
        expect(Set.new(less_dependent_transform.available_unused_prerequisite_transforms)).to eq(Set.new([independent_transform, first_child_transform, another_less_dependent_transform]))
        expect(Set.new(another_less_dependent_transform.available_unused_prerequisite_transforms)).to eq(Set.new([independent_transform, first_child_transform, less_dependent_transform]))
        expect(Set.new(least_dependent_transform.available_unused_prerequisite_transforms)).to eq(Set.new([independent_transform, first_child_transform]))
        expect(Set.new(independent_transform.available_unused_prerequisite_transforms)).to eq(Set.new([most_dependent_transform, first_child_transform, less_dependent_transform, another_less_dependent_transform, least_dependent_transform]))

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
