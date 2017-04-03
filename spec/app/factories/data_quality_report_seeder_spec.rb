# frozen_string_literal: true
describe DataQualityReportSeeder do

  describe "#seed" do

    it "should idempotently create some data quality reports" do
      expect(DataQualityReport.count).to eq(0)
      expect { DataQualityReportSeeder.seed }.to_not raise_error
      count = DataQualityReport.count
      expect(count).to be > 0
      expect { DataQualityReportSeeder.seed }.to_not raise_error
      new_count = DataQualityReport.count
      expect(new_count).to eq(count)
    end
  end


end
