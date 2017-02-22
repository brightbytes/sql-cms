# == Schema Information
#
# Table name: public.workflows
#
#  id          :integer          not null, primary key
#  name        :string           not null
#  slug        :string           not null
#  customer_id :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_workflows_on_customer_id     (customer_id)
#  index_workflows_on_lowercase_name  (lower((name)::text)) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (customer_id => customers.id)
#

describe Workflow do

  describe 'versioned by PaperTrail' do
    it { is_expected.to be_versioned }
  end

  describe 'validations' do
    [:name, :customer, :slug].each do |att|
      it { should validate_presence_of(att) }
    end

    context 'with a workflow already extant' do
      let!(:subject) { create(:workflow) }
      it { should validate_uniqueness_of(:name).case_insensitive }
      it { should validate_uniqueness_of(:slug).case_insensitive }
    end

  end

  describe 'associations' do
    it { should belong_to(:customer) }
    it { should have_many(:notifications) }
    it { should have_many(:notified_users).through(:notifications).source(:user) }
    it { should have_many(:transforms) }
    it { should have_many(:data_quality_reports) }
    it { should have_many(:runs) }
  end

  describe 'instance methods' do

    it "should coerce invalid slugs to valid slugs on set" do
      workflow = build(:workflow, slug: "0foo 1$BAR_")
      expect(workflow.slug).to eq("_foo_1_bar_")
      workflow = build(:workflow, slug: "foo 123 %@#_")
      expect(workflow.slug).to eq("foo_123_")
    end

    context "#to_s" do
      let!(:subject) { create(:workflow) }

      it "should return the concatenation of the customer slug, an underscore, and the slug" do
        expect(subject.to_s).to eq("#{subject.customer.slug}_#{subject.slug}")
      end
    end

    context "#emails_to_notify" do
      it "should simply return a list of notified_user emails" do
        notification_1 = create(:notification)
        workflow = notification_1.workflow
        notification_2 = create(:notification, workflow: workflow)
        notification_3 = create(:notification, workflow: workflow)
        ignored_notification = create(:notification)
        expect(Set.new(workflow.emails_to_notify)).to eq(Set.new([notification_1, notification_2, notification_3].map(&:user).map(&:email)))
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
        include_examples 'cheesey dependency graph'

        it "should group transforms accordingly" do
          expect(workflow.ordered_transform_groups).to eq([Set.new([independent_transform, least_dependent_transform, first_child_transform]), Set.new([less_dependent_transform, another_less_dependent_transform]), Set.new([most_dependent_transform])])
        end
      end

      context "with the cheesey dependency graph and extra, redundant dependencies that shouldn't change the result" do
        include_examples 'cheesey dependency graph'

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

  end
end
