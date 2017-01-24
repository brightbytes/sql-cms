describe DataQualityReport do

  describe 'versioned by PaperTrail' do
    it { is_expected.to be_versioned }
  end

  describe "validations" do
    [:name, :sql, :workflow].each do |att|
      it { should validate_presence_of(att) }
    end

    context "with a data_quality_report already extant" do
      let!(:subject) { create(:data_quality_report) }
      it { should validate_uniqueness_of(:name).case_insensitive }
    end

    it "should validate that sql_params is not null, but allow blank" do
      dqr = create(:data_quality_report)
      dqr.sql_params = nil
      expect(dqr.valid?).to be false

      dqr.sql_params = {}
      expect(dqr.valid?).to be true
    end

  end

  describe "associations" do
    it { should belong_to(:workflow) }

    it { should belong_to(:copied_from_data_quality_report) }
    it { should have_many(:copied_to_data_quality_reports) }
  end

end
