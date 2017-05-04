# == Schema Information
#
# Table name: public.workflows
#
#  id             :integer          not null, primary key
#  name           :string           not null
#  slug           :string           not null
#  customer_id    :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  shared         :boolean          default(FALSE), not null
#  s3_region_name :string           not null
#  s3_bucket_name :string           not null
#  s3_file_path   :string
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
    [:name, :slug, :s3_region_name, :s3_bucket_name].each do |att|
      it { should validate_presence_of(att) }
    end

    it "should validate the presence of the customer when the workflow isn't shared" do
      workflow = build(:workflow, customer: nil, shared: false)
      expect(workflow).to_not be_valid
      workflow.customer = create(:customer)
      expect(workflow).to be_valid
    end

    it "should validate the absence of the customer when the workflow is shared" do
      workflow = build(:workflow, customer: create(:customer), shared: true)
      expect(workflow).to_not be_valid
      workflow.customer = nil
      expect(workflow).to be_valid
    end

    context 'with a workflow already extant' do
      let!(:subject) { create(:workflow) }
      it { should validate_uniqueness_of(:name).case_insensitive }
      it { should validate_uniqueness_of(:slug).case_insensitive }
    end

  end

  describe "callbacks" do
    it "should be immutable against destroy when flagged as such" do
      workflow = create(:workflow)
      expect(workflow.immutable?).to eq(false)
      expect(workflow.read_only?).to eq(false)
      workflow.update_attribute(:immutable, true)
      expect { workflow.destroy }.to raise_error("You may not destroy an immutable Workflow")
      expect { workflow.delete }.to raise_error("You may not bypass callbacks to delete a Class.")
    end

    it "should prevent bulk-deletes" do
      expect { Workflow.delete_all }.to raise_error("You may not bypass callbacks to delete all the Workflow that exist, since some may be inviolate.")
    end
  end

  describe 'associations' do
    it { should belong_to(:customer) }
    it { should have_many(:notifications) }
    it { should have_many(:notified_users).through(:notifications).source(:user) }
    it { should have_many(:transforms) }
    it { should have_many(:data_quality_reports) }
    it { should have_many(:runs) }

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
      it "should return the concatenation of the customer slug (or :shared for a Shared Workflow), an underscore, and the slug" do
        normal_workflow = create(:workflow)
        expect(normal_workflow.to_s).to eq("#{normal_workflow.customer.slug}_#{normal_workflow.slug}")
        shared_workflow = create(:shared_workflow)
        expect(shared_workflow.to_s).to eq("shared_#{shared_workflow.slug}")
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
