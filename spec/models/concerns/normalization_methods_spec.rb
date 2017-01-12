describe Concerns::NormalizationMethods do

  before(:all) do
    ActiveSupport::Deprecation.silence do

      # Using acts_as_fu to create a model specifically for our extension
      build_model :normalizeables do
        string :column1
        string :column2
        string :column3
        include Concerns::NormalizationMethods
      end

    end
  end

  describe '.auto_normalize' do
    before do
      Normalizeable.send(:auto_normalize, except: :column3)
    end

    subject do
      record = Normalizeable.new
      record.column1 = '  foo   bar   '
      record.column2 = '   baz  min   '
      record.column3 = '  raw data    '
      record
    end

    it "should normalize the 2 specified atts" do
      expect(subject.column1).to eq('foo bar')
      expect(subject.column2).to eq('baz min')
      expect(subject.column3).to eq('  raw data    ')
    end
  end

  context ".normalize_attr" do
    before do
      Normalizeable.send(:normalize_attr, :column1, :column2)
      @normalizeable = Normalizeable.new
    end

    it "should strip leading and trailing spaces, and squish strings of spaces in between words down to 1 space" do
      @normalizeable.column1 = "  foo    bar  dude    "
      @normalizeable.column2 = "blah yuck dude"
      expect(@normalizeable.column1).to eq("foo bar dude")
      expect(@normalizeable.column2).to eq("blah yuck dude")
    end
  end

  context ".normalize_email_attr" do
    before do
      Normalizeable.send(:normalize_email_attr, :column1, :column2)
      @normalizeable = Normalizeable.new
    end

    it "should strip leading and trailing spaces, and downcase the val" do
      @normalizeable.column1 = "  FOO@BAR.COM    "
      @normalizeable.column2 = "shoobie@doo.com"
      expect(@normalizeable.column1).to eq("foo@bar.com")
      expect(@normalizeable.column2).to eq("shoobie@doo.com")
    end
  end

  context "#numberize" do
    before do
      @normalizeable = Normalizeable.new
    end

    it "should add a convenience method for removing non-numbers from a string" do
      expect(@normalizeable.numberize(" foo (123) - 4 5 6, 78 9 wefjh 0  ")).to eq("1234567890")
    end
  end

  context ".normalize_slug_attr" do
    before do
      Normalizeable.send(:normalize_slug_attr, :column1, :column2)
      @normalizeable = Normalizeable.new
    end

    it "should strip leading and trailing spaces, and downcase the val" do
      @normalizeable.column1 = "  iAmA sLuG    "
      @normalizeable.column2 = " i amaslug"
      expect(@normalizeable.column1).to eq("iamaslug")
      expect(@normalizeable.column2).to eq("iamaslug")
    end
  end
end
