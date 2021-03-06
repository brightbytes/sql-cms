# == Schema Information
#
# Table name: workflows
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  slug       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  params     :jsonb
#
# Indexes
#
#  index_workflows_on_lowercase_name  (lower((name)::text)) UNIQUE
#  index_workflows_on_lowercase_slug  (lower((slug)::text)) UNIQUE
#

describe Workflow, type: :model do

  describe 'versioned by PaperTrail' do
    it { is_expected.to be_versioned }
  end

  describe 'validations' do
    [:name, :slug].each do |att|
      it { should validate_presence_of(att) }
    end

    context 'with a workflow already extant' do
      let!(:subject) { create(:workflow) }
      it { should validate_uniqueness_of(:name).case_insensitive }
      it { should validate_uniqueness_of(:slug).case_insensitive }
    end

  end

  describe "callbacks" do
    it "should raise an error if an attempt is made to destroy a workflow that is included by another workflow" do
      dependency = create(:workflow_dependency)
      expect { dependency.included_workflow.destroy }.to raise_error(RuntimeError)
      expect { dependency.including_workflow.destroy }.to_not raise_error
    end
  end

  describe 'associations' do
    it { should have_many(:workflow_configurations) }

    it { should have_many(:transforms) }
    it { should have_many(:data_quality_reports) }

    it { should have_many(:included_dependencies) }
    it { should have_many(:included_workflows).through(:included_dependencies) }
    it { should have_many(:including_dependencies) }
    it { should have_many(:including_workflows).through(:including_dependencies) }
  end

  describe 'instance methods' do

    it "should coerce invalid slugs to valid slugs on set" do
      workflow = build(:workflow, slug: "0foo 1$BAR_")
      expect(workflow.slug).to eq("_foo_1_bar")
      workflow = build(:workflow, slug: "foo 123 %@#_")
      expect(workflow.slug).to eq("foo_123")
    end

    context "#to_s" do
      it "should return the workflow slug" do
        workflow = create(:workflow)
        expect(workflow.to_s).to eq(workflow.slug)
      end
    end

    context "#ordered_transform_groups" do

      context "with a linear graph" do
        let!(:workflow) { create(:workflow) }

        let!(:gramps_transform) { create(:transform, workflow: workflow) }
        let!(:daddy_transform) { create(:transform, workflow: workflow) }
        let!(:dependency_1) { create(:transform_dependency, prerequisite_transform: daddy_transform, postrequisite_transform: gramps_transform) }
        let!(:son_transform) { create(:transform, workflow: workflow) }
        let!(:dependency_2) { create(:transform_dependency, prerequisite_transform: son_transform, postrequisite_transform: daddy_transform) }

        it "should define the correct grouping, without maxing-out iterations" do
          expect(workflow.ordered_transform_groups).to eq([Set.new([son_transform]), Set.new([daddy_transform]), Set.new([gramps_transform])])
        end
      end

      context "with the cheesey dependency graph" do
        include_examples 'cheesey transform dependency graph'

        it "should group transforms accordingly" do
          expect(workflow.ordered_transform_groups).to eq([Set.new([independent_transform, least_dependent_transform, first_child_transform]), Set.new([less_dependent_transform, another_less_dependent_transform]), Set.new([most_dependent_transform])])
        end
      end

      context "with the cheesey dependency graph and extra, redundant dependencies that shouldn't change the result" do
        include_examples 'cheesey transform dependency graph'

        let!(:dependency_6) { create(:transform_dependency, prerequisite_transform: least_dependent_transform, postrequisite_transform: most_dependent_transform) }
        let!(:dependency_7) { create(:transform_dependency, prerequisite_transform: independent_transform, postrequisite_transform: most_dependent_transform) }
        let!(:dependency_8) { create(:transform_dependency, prerequisite_transform: independent_transform, postrequisite_transform: less_dependent_transform) }
        let!(:dependency_9) { create(:transform_dependency, prerequisite_transform: independent_transform, postrequisite_transform: another_less_dependent_transform) }

        it "should group transforms accordingly" do
          expect(workflow.ordered_transform_groups).to eq([Set.new([independent_transform, least_dependent_transform, first_child_transform]), Set.new([less_dependent_transform, another_less_dependent_transform]), Set.new([most_dependent_transform])])
        end
      end

      context "with a cyclical graph" do
        let!(:workflow) { create(:workflow) }

        let!(:yin_transform) { create(:transform, workflow: workflow) }
        let!(:yang_transform) { create(:transform, workflow: workflow) }
        let!(:dependency_1) { create(:transform_dependency, prerequisite_transform: yin_transform, postrequisite_transform: yang_transform) }
        let!(:dependency_2) { create(:transform_dependency, prerequisite_transform: yang_transform, postrequisite_transform: yin_transform) }

        it "should terminate irrespective of the cycle, and puke noisily" do
          expect { workflow.ordered_transform_groups }.to raise_error(RuntimeError)
        end

        context "even if there is an independent transform" do
          let!(:void_transform) { create(:transform, workflow: workflow) }

          it "should terminate irrespective of the cycle, and puke noisily" do
            expect { workflow.ordered_transform_groups }.to raise_error(RuntimeError)
          end
        end

        context "even if the cycle is above a leaf node" do
          let!(:mu_transform) { create(:transform, workflow: workflow) }
          let!(:dependency_3) { create(:transform_dependency, prerequisite_transform: mu_transform, postrequisite_transform: yin_transform) }

          it "should terminate irrespective of the cycle, and puke noisily" do
            expect { workflow.ordered_transform_groups }.to raise_error(RuntimeError)
          end
        end

      end

    end

    context "#available_included_workflows" do

      include_examples 'cheesey workflow dependency graph'

      it "should return the correct list of includables in all cases" do

        expect(Set.new(Workflow.new.available_included_workflows)).to eq(Set.new([parent_workflow, child_workflow_1, child_workflow_2, grandchild_workflow_2_1, great_grandchild_workflow_2_1_1, independent_workflow]))

        expect(Set.new(parent_workflow.available_included_workflows)).to eq(Set.new([child_workflow_1, child_workflow_2, grandchild_workflow_2_1, great_grandchild_workflow_2_1_1, independent_workflow]))

        expect(Set.new(child_workflow_1.available_included_workflows)).to eq(Set.new([child_workflow_2, grandchild_workflow_2_1, great_grandchild_workflow_2_1_1, independent_workflow]))

        expect(Set.new(child_workflow_2.available_included_workflows)).to eq(Set.new([child_workflow_1, grandchild_workflow_2_1, great_grandchild_workflow_2_1_1, independent_workflow]))

        expect(Set.new(grandchild_workflow_2_1.available_included_workflows)).to eq(Set.new([child_workflow_1, great_grandchild_workflow_2_1_1, independent_workflow]))

        expect(Set.new(great_grandchild_workflow_2_1_1.available_included_workflows)).to eq(Set.new([child_workflow_1, independent_workflow]))

      end

    end

  end
end
