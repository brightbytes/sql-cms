# frozen_string_literal: true
# == Schema Information
#
# Table name: public.data_files
#
#  id             :integer          not null, primary key
#  name           :string           not null
#  metadata       :jsonb            not null
#  customer_id    :integer          not null
#  s3_bucket_name :string           not null
#  s3_file_name   :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  deleted_at     :datetime
#
# Indexes
#
#  index_data_files_on_customer_id     (customer_id)
#  index_data_files_on_lowercase_name  (lower((name)::text)) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (customer_id => customers.id)
#

describe DataFile do

  describe 'versioned by PaperTrail' do
    it { is_expected.to be_versioned }
  end

  describe "validations" do
    [:name, :customer, :s3_bucket_name, :s3_file_name].each do |att|
      it { should validate_presence_of(att) }
    end

    it "should validate that metadata is not null, but allow blank" do
      pt = create(:data_file)
      pt.metadata = nil
      expect(pt.valid?).to be false

      pt.metadata = {}
      expect(pt.valid?).to be true
    end

    context "with a data_file already extant" do
      let!(:subject) { create(:data_file) }
      it { should validate_uniqueness_of(:name).case_insensitive }
    end

  end

  describe "callbacks" do
    context "before_validation" do
      it "should parse a supplied s3-resource URL regardless of format" do
        df = build(:data_file, s3_bucket_name: nil, s3_file_name: nil)
        df.supplied_s3_url = "https://s3-us-west-2.amazonaws.com/bb-pipeline-production-rawdata/ca_pleasant_valley_sis/v_2_201610212151_custom/calendars_2017.tsv/part_0000.tsv"
        expect(df.valid?).to eq(true)
        expect(df.s3_bucket_name).to eq('bb-pipeline-production-rawdata')
        expect(df.s3_file_name).to eq('ca_pleasant_valley_sis/v_2_201610212151_custom/calendars_2017.tsv/part_0000.tsv')

        df = build(:data_file, s3_bucket_name: nil, s3_file_name: nil)
        df.supplied_s3_url = "s3://bb-pipeline-production-rawdata/ca_pleasant_valley_sis/v_2_201610212151_custom/calendars_2017.tsv/part_0000.tsv"
        expect(df.valid?).to eq(true)
        expect(df.s3_bucket_name).to eq('bb-pipeline-production-rawdata')
        expect(df.s3_file_name).to eq('ca_pleasant_valley_sis/v_2_201610212151_custom/calendars_2017.tsv/part_0000.tsv')

        df = build(:data_file, s3_bucket_name: nil, s3_file_name: nil)
        df.supplied_s3_url = "https://s3-us-west-2.amazonaws.com/bb-pipeline-production-rawdata"
        expect(df.valid?).to eq(false)

        df = build(:data_file, s3_bucket_name: nil, s3_file_name: nil)
        df.supplied_s3_url = "s3://bb-pipeline-production-rawdata"
        expect(df.valid?).to eq(false)
      end
    end
  end

  describe "associations" do
    it { should belong_to(:customer) }
    it { should have_many(:transforms) }
    it { should have_many(:workflows) }
  end
end
