# == Schema Information
#
# Table name: public.data_files
#
#  id             :integer          not null, primary key
#  name           :string           not null
#  customer_id    :integer          not null
#  file_type      :string           default("import"), not null
#  s3_region_name :string           default("us-west-2"), not null
#  s3_bucket_name :string           not null
#  s3_file_name   :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  s3_file_path   :string
#
# Indexes
#
#  index_data_files_on_customer_id                     (customer_id)
#  index_data_files_on_lowercase_name_and_customer_id  (lower((name)::text), customer_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (customer_id => customers.id)
#

describe DataFile do

  # S3Logic.instance_variable_set(:@client, Aws::S3::Client.new(stub_responses: true))

  describe 'versioned by PaperTrail' do
    it { is_expected.to be_versioned }
  end

  describe "validations" do
    [:name, :customer, :file_type, :s3_region_name, :s3_bucket_name, :s3_file_name].each do |att|
      it { should validate_presence_of(att) }
    end

    it { should validate_inclusion_of(:file_type).in_array(described_class::FILE_TYPES) }

    context "with a data_file already extant" do
      let!(:subject) { create(:data_file) }
      it { should validate_uniqueness_of(:name).case_insensitive }
    end

  end

  describe "callbacks" do
    context "before_validation" do
      it "should parse a supplied s3-resource URL regardless of format" do
        df = build(:data_file, s3_bucket_name: nil, s3_file_path: nil, s3_file_name: nil)
        df.supplied_s3_url = "https://s3-us-west-2.amazonaws.com/bb-rawdata/ca_some_sis/v_2_201610212151_custom/calendars_2017.tsv"
        expect(df.valid?).to eq(true)
        expect(df.s3_region_name).to eq('us-west-2')
        expect(df.s3_bucket_name).to eq('bb-rawdata')
        expect(df.s3_file_path).to eq('ca_some_sis/v_2_201610212151_custom')
        expect(df.s3_file_name).to eq('calendars_2017.tsv')

        df = build(:data_file, s3_bucket_name: nil, s3_file_path: nil, s3_file_name: nil)
        df.supplied_s3_url = "https://s3-us-west-2.amazonaws.com/bb-rawdata/calendars_2017.tsv"
        expect(df.valid?).to eq(true)
        expect(df.s3_region_name).to eq('us-west-2')
        expect(df.s3_bucket_name).to eq('bb-rawdata')
        expect(df.s3_file_path).to eq(nil)
        expect(df.s3_file_name).to eq('calendars_2017.tsv')

        df = build(:data_file, s3_bucket_name: nil, s3_file_path: nil, s3_file_name: nil)
        df.supplied_s3_url = "https://s3-us-west-2.amazonaws.com/bb-pipeline-production-rawdata"
        expect(df.valid?).to eq(false)

        df = build(:data_file, s3_bucket_name: nil, s3_file_path: nil, s3_file_name: nil)
        df.supplied_s3_url = "s3://bb-pipeline-production-rawdata"
        expect(df.valid?).to eq(false)
      end
    end

    context "before_destoy" do
      it "should prevent destroy if one or more transforms are using the DataFile" do
        df = create(:data_file)
        expect { df.destroy }.to_not raise_error

        df = create(:data_file)
        t = create(:transform, runner: "CopyFrom", data_file: df)
        df.reload
        expect { df.destroy }.to raise_error(RuntimeError)
      end
    end
  end

  describe "associations" do
    it { should belong_to(:customer) }
    it { should have_many(:transforms) }
    it { should have_many(:workflows) }
  end

  describe "instance methods" do
    it "should have a #used? method that returns true only when there are one or more Transforms associated with the DataFile" do
      df = create(:data_file)
      expect(df.used?).to eq(false)

      t = create(:transform, runner: "CopyFrom", data_file: df)
      df.reload
      expect(df.used?).to eq(true)
    end

    it "should have #import? and #export? convenience methods wrapping the file_type attribute" do
      df = create(:data_file, file_type: :import)
      expect(df.import?).to eq(true)
      expect(df.export?).to eq(false)

      df = create(:data_file, file_type: :export)
      expect(df.import?).to eq(false)
      expect(df.export?).to eq(true)
    end
  end
end
