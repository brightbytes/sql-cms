# == Schema Information
#
# Table name: customers
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  slug       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  deleted_at :datetime
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
    it { should validate_presence_of(:slug) }

    context "with a Customer already extant" do
      it { should validate_uniqueness_of(:name).case_insensitive }
      it { should validate_uniqueness_of(:slug).case_insensitive }
    end

    context "slug validation" do
      it "shouldn't allow updating once set" do
        subject.slug = "foobar"
        expect(subject).to_not be_valid
        expect(subject.errors[:slug]).to_not be_nil
      end

      it "shouldn't allow an illegal identifier" do
        customer = build(:customer, slug: "0foo") # a leading number is all we can sneak past coercion
        expect(customer).to_not be_valid
        expect(customer.errors[:slug]).to_not be_nil
      end
    end
  end

  describe "associations" do
    # it { should have_many(:workflows) }
    it { should have_many(:data_files) }
  end

  describe "scopes" do

  end

  describe "callbacks" do

  end

  describe "instance methods" do
    it "should coerce invalid slugs to valid slugs on set" do
      customer = build(:customer, slug: "0foo 1$BAR_")
      expect(customer.slug).to eq("0foo_1_bar_")
      customer = build(:customer, slug: "foo 123 %@#_")
      expect(customer.slug).to eq("foo_123_")
    end

    context "#to_s" do
      it "should return the slug" do
        expect(subject.to_s).to eq(subject.slug)
      end
    end
  end
end
