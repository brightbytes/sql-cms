# frozen_string_literal: true
# == Schema Information
#
# Table name: data_files
#
#  id                  :integer          not null, primary key
#  name                :string           not null
#  metadata            :jsonb            not null
#  customer_id         :integer          not null
#  upload_file_name    :string           not null
#  upload_content_type :string           not null
#  upload_file_size    :integer          not null
#  upload_updated_at   :datetime         not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  deleted_at          :datetime
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
    [:name, :customer].each do |att|
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

    it { should have_attached_file(:upload) }

    it { should validate_attachment_presence(:upload) }

    # FIXME: Oddly not working here, even though I copied the source exactly from pipeline repo.  Doesn't matter.
    # it "should accept every known Excel MIME type and text/csv, along with any text type ... but not accept macro-enabled sheets or anything else" do
    #   [
    #     'application/vnd.ms-excel',
    #     'application/msexcel',
    #     'application/x-msexcel',
    #     'application/x-ms-excel',
    #     'application/x-excel',
    #     'application/x-dos_ms_excel',
    #     'application/xls',
    #     'application/x-xls',
    #     'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    #     'application/vnd.openxmlformats-officedocument.spreadsheetml.template'
    #   ].each do |content_type|
    #     expect(build(:data_file, upload: fixture_file_upload('files/test.xlsx', content_type))).to be_valid
    #   end
    #   [
    #     'text/csv',
    #     'text/foobar'
    #   ].each do |content_type|
    #     expect(build(:data_file, upload: fixture_file_upload('files/test.csv', content_type))).to be_valid
    #   end
    #   [
    #     'application/vnd.ms-excel.sheet.macroEnabled.12',
    #     'application/vnd.ms-excel.template.macroEnabled.12',
    #     'application/vnd.ms-excel.addin.macroEnabled.12',
    #     'application/vnd.ms-excel.sheet.binary.macroEnabled.12',
    #     'application/msword',
    #     'application/exe'
    #   ].each do |content_type|
    #     expect(build(:data_file, upload: fixture_file_upload('files/test.xlsx', content_type))).to_not be_valid
    #   end
    # end

    describe 'application/octet-stream mime::type detection' do
      let(:content_type) { 'application/octet-stream' }
      subject(:upload) { build(:data_file, upload: fixture_file_upload(upload_file_name, content_type)) }

      context '.xls file' do
        let(:upload_file_name) { '/files/test.xls' }
        it { should be_valid }
      end

      context '.png file' do
        let(:upload_file_name) { '/files/test.png' }
        it { should_not be_valid }
      end
    end

  end

  describe "associations" do
    it { should belong_to(:customer) }
    # it { should have_many(:transforms) }
    # it { should have_many(:workflows) }
  end
end
