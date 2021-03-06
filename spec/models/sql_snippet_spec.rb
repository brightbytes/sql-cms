# == Schema Information
#
# Table name: sql_snippets
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

describe SqlSnippet, type: :model do

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:slug) }
    it { should validate_presence_of(:sql) }

    context "with a Customer already extant" do
      let!(:subject) { create(:sql_snippet) }
      it { should validate_uniqueness_of(:name).case_insensitive }
      it { should validate_uniqueness_of(:slug).case_insensitive }
    end

    it "should only allow valid slugs" do
      expect(build(:sql_snippet, slug: "1foobar")).to_not be_valid
      expect(build(:sql_snippet, slug: "foobar1")).to be_valid
      expect(build(:sql_snippet, slug: "foobar_1")).to be_valid
      expect(build(:sql_snippet, slug: "_foobar")).to_not be_valid
      expect(build(:sql_snippet, slug: "foobar_")).to_not be_valid
      expect(build(:sql_snippet, slug: "foo_bar")).to be_valid
      expect(build(:sql_snippet, slug: "Foobar")).to_not be_valid
      expect(build(:sql_snippet, slug: "foobaR")).to_not be_valid
      expect(build(:sql_snippet, slug: "foobar")).to be_valid
    end
  end

  describe "callbacks" do
    context "before_destroy" do
      it "should prevent destruction if the SqlSnippet is used" do
        sql_snippet = create(:sql_snippet)
        transform = create(:transform, sql: ":#{sql_snippet.slug}:")
        expect { sql_snippet.destroy }.to raise_error(StandardError)
        transform.destroy
        sql_snippet.reload
        expect { sql_snippet.destroy }.to_not raise_error
      end
    end
  end

  describe "instance methods" do
    it "should handle quotes in the interpolated sql correctly" do
      sql_snippet = create(:sql_snippet, sql: "SELECT ':column_name'")
      transform = create(:transform, sql: ":#{sql_snippet.slug}:", params: { column_name: 'whatever' })
      expect(transform.interpolated_sql).to eq("SELECT 'whatever'")
    end
  end

end
