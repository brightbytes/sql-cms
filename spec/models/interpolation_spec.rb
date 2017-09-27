# == Schema Information
#
# Table name: interpolations
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  slug       :string           not null
#  sql        :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_interpolations_on_lowercase_name  (lower((name)::text)) UNIQUE
#  index_interpolations_on_lowercase_slug  (lower((slug)::text)) UNIQUE
#

describe Interpolation do

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:slug) }
    it { should validate_presence_of(:sql) }

    context "with a Customer already extant" do
      let!(:subject) { create(:interpolation) }
      it { should validate_uniqueness_of(:name) }
      it { should validate_uniqueness_of(:slug) }
    end

    it "should only allow valid slugs" do
      expect(build(:interpolation, slug: "1foobar")).to_not be_valid
      expect(build(:interpolation, slug: "foobar1")).to be_valid
      expect(build(:interpolation, slug: "foobar_1")).to be_valid
      expect(build(:interpolation, slug: "_foobar")).to_not be_valid
      expect(build(:interpolation, slug: "foobar_")).to_not be_valid
      expect(build(:interpolation, slug: "foo_bar")).to be_valid
      expect(build(:interpolation, slug: "Foobar")).to_not be_valid
      expect(build(:interpolation, slug: "foobaR")).to_not be_valid
      expect(build(:interpolation, slug: "foobar")).to be_valid
    end
  end

  describe "callbacks" do
    context "before_destroy" do
      it "should prevent destruction if the Interpolation is used" do
        interpolation = create(:interpolation)
        transform = create(:transform, sql: ":#{interpolation.slug}:")
        expect { interpolation.destroy }.to raise_error(StandardError)
        transform.destroy
        interpolation.reload
        expect { interpolation.destroy }.to_not raise_error
      end
    end
  end

  describe "instance methods" do
    it "should handle quotes in the interpolated sql correctly" do
      interpolation = create(:interpolation, sql: "SELECT ':column_name'")
      transform = create(:transform, sql: ":#{interpolation.slug}:", params: { column_name: 'whatever' })
      expect(transform.interpolated_sql).to eq("SELECT 'whatever'")
    end
  end

end
