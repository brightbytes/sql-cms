# == Schema Information
#
# Table name: workflows
#
#  id                      :integer          not null, primary key
#  name                    :string           not null
#  schema_base_name        :string           not null
#  dbms                    :string           default("postgres"), not null
#  customer_id             :integer          not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  copied_from_workflow_id :integer
#
# Indexes
#
#  index_workflows_on_copied_from_workflow_id     (copied_from_workflow_id)
#  index_workflows_on_customer_id                 (customer_id)
#  index_workflows_on_lowercase_name              (lower((name)::text)) UNIQUE
#  index_workflows_on_lowercase_schema_base_name  (lower((schema_base_name)::text)) UNIQUE
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
    [:name, :dbms, :schema_base_name, :customer].each do |att|
      it { should validate_presence_of(att) }
    end

    it { should validate_inclusion_of(:dbms).in_array(described_class::DBMS_TYPES) }

    context 'with a workflow already extant' do
      let!(:subject) { create(:workflow) }
      it { should validate_uniqueness_of(:name).case_insensitive }
    end

    context 'with a workflow already extant' do
      let!(:subject) { create(:workflow) }
      it { should validate_uniqueness_of(:schema_base_name).case_insensitive }
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

    it "should coerce invalid schema_base_names to valid schema_base_names on set" do
      workflow = build(:workflow, schema_base_name: "0foo 1$BAR_")
      expect(workflow.schema_base_name).to eq("_foo_1_bar_")
      workflow = build(:workflow, schema_base_name: "foo 123 %@#_")
      expect(workflow.schema_base_name).to eq("foo_123_")
    end

    context "#to_s" do
      let!(:subject) { create(:workflow) }

      it "should return the concatenation of the customer slug, an underscore, and the schema base name" do
        expect(subject.to_s).to eq("#{subject.customer.slug}_#{subject.schema_base_name}")
      end
    end

  end
end
