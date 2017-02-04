# == Schema Information
#
# Table name: public.workflows
#
#  id                      :integer          not null, primary key
#  name                    :string           not null
#  slug                    :string           not null
#  customer_id             :integer          not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  copied_from_workflow_id :integer
#
# Indexes
#
#  index_workflows_on_copied_from_workflow_id  (copied_from_workflow_id)
#  index_workflows_on_customer_id              (customer_id)
#  index_workflows_on_lowercase_name           (lower((name)::text)) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (copied_from_workflow_id => workflows.id)
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
    it { should belong_to(:copied_from_workflow) }
    it { should have_many(:copied_to_workflows) }
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

      context "with the cheesey dependency graph" do
        include_examples 'cheesey dependency graph'

        it "should group transforms accordingly" do
          expect(workflow.ordered_transform_groups).to eq([Set.new([independent_transform, least_dependent_transform, first_child_transform]), Set.new([less_dependent_transform, another_less_dependent_transform]), Set.new([most_dependent_transform])])
        end
      end


    end

  end
end
