# == Schema Information
#
# Table name: customers
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  slug       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_customers_on_lowercase_name  (lower((name)::text)) UNIQUE
#  index_customers_on_lowercase_slug  (lower((slug)::text)) UNIQUE
#

describe Customer do

  let!(:subject) { create(:customer) }

  describe "validations" do
    it { should validate_presence_of(:name) }

    context "with a Customer already extant" do
      it { should validate_uniqueness_of(:name).case_insensitive }
      it { should validate_uniqueness_of(:slug).case_insensitive }
    end
  end

  describe "associations" do
    it { should have_many(:workflow_configurations) }
  end

  describe "scopes" do

  end

  describe "callbacks" do

  end

  describe "instance methods" do
    it "should coerce invalid slugs to valid slugs on set" do
      customer = build(:customer, slug: "0foo 1$BAR_")
      expect(customer.slug).to eq("_foo_1_bar")
      customer = build(:customer, slug: "foo 123 %@#_")
      expect(customer.slug).to eq("foo_123")
    end

    context "#to_s" do
      it "should return the slug" do
        expect(subject.to_s).to eq(subject.slug)
      end
    end

    context "#used?" do
      it "should return true iff a workflow_configuration is defined for the customer" do
        customer = create(:customer)
        expect(customer.used?).to eq(false)
        create(:workflow_configuration, customer: customer)
        customer.reload
        expect(customer.used?).to eq(true)
      end
    end
  end
end
