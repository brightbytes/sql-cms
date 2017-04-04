# == Schema Information
#
# Table name: public.data_quality_reports
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  sql        :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  immutable  :boolean          default(FALSE)
#
# Indexes
#
#  index_data_quality_reports_on_lowercase_name  (lower((name)::text)) UNIQUE
#

describe DataQualityReport do

  describe 'versioned by PaperTrail' do
    it { is_expected.to be_versioned }
  end

  describe "validations" do
    [:name, :sql].each do |att|
      it { should validate_presence_of(att) }
    end

    context "with a data_quality_report already extant" do
      let!(:subject) { create(:data_quality_report) }
      it { should validate_uniqueness_of(:name).case_insensitive }
    end

  end

  describe "callbacks" do
    it "should be immutable when flagged as such" do
      data_quality_report = create(:data_quality_report)
      expect(data_quality_report.immutable?).to eq(false)
      expect(data_quality_report.read_only?).to eq(false)
      data_quality_report.update_attribute(:immutable, true)
      expect { data_quality_report.destroy }.to raise_error("You may not destroy an immutable DataQualityReport")
      expect { data_quality_report.delete }.to raise_error("You may not bypass callbacks to delete a Class.")
      expect { data_quality_report.update_attribute(:sql, "/* Blah */") }.to raise_error("You may not update an immutable DataQualityReport")
      expect { data_quality_report.update_attributes(sql: "/* Blah */") }.to raise_error("You may not update an immutable DataQualityReport")
      expect { data_quality_report.update_column(:sql, "/* Blah */") }.to raise_error("You may not bypass callbacks to update a Class.")
    end

    it "should prevent bulk-updates" do
      expect { DataQualityReport.delete_all }.to raise_error("You may not bypass callbacks to delete all the DataQualityReport that exist, since some may be inviolate.")
      expect { DataQualityReport.update_all(sql: "/* Blah */") }.to raise_error("You may not bypass callbacks to update all the DataQualityReport that exist, since some may be inviolate.")
    end
  end

  describe "associations" do
    it { should have_many(:workflow_data_quality_reports) }
    it { should have_many(:workflows) }
  end

  describe "instance methods" do

    context "#usage_count" do
      it "should return the number of times the DataQualityReport is used" do
        dqr = create(:data_quality_report)
        expect(dqr.usage_count).to eq(0)
        3.times { create(:workflow_data_quality_report, data_quality_report: dqr) }
        expect(dqr.reload.usage_count).to eq(3)
      end
    end

  end

end
