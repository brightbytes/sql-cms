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

# NOTE - We will use PaperClip differently here than in the `pipeline` repo.  Here, we will build a browser for files already on S3, using this example:
#          https://www.topdan.com/ruby-on-rails/aws-s3-browser.html
#        Then, we will associate the PaperClip class with the selected already-existing file on S3, using this example:
#          http://stackoverflow.com/questions/3961107/using-paperclip-with-files-already-on-amazon-s3
#        ... though the browser isn't necessary if a queued message arrives with the relevant data.
class DataFile < ActiveRecord::Base

  acts_as_paranoid

  auto_normalize

  has_attached_file :upload, s3_headers: lambda { |attachment|
    {
      "Content-Type" => MIME::Types.type_for(attachment.name).first.try(:to_s),
      "Content-Disposition" => "attachment; filename=#{attachment.name}"
    }
  }

  # Validations

  validates :customer, presence: true

  validate :metadata_not_null

  def metadata_not_null
    errors.add(:metadata, 'may not be null') unless metadata # {} is #blank?, hence this hair
  end

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  validates :upload, attachment_presence: true

  validates_attachment_content_type :upload, content_type: /(?:text\/)|(?:application\/.*(?:excel|sheet|xls)(?!.*macro))|inode\/x-empty/i

  # Callbacks

  # Fix wrong content type detection on client side
  before_validation on: :create do
    if upload_content_type.in?(['application/octet-stream', 'text/plain', 'application/x-ole-storage'])
      if mime_type = MIME::Types.type_for(upload_file_name).first.try(:to_s)
        self.upload_content_type = mime_type
      end
    end
  end

  # Associations

  belongs_to :customer, inverse_of: :data_files

  has_many :transforms, inverse_of: :data_file
  has_many :workflows, through: :transforms

  # Instance Methods

  alias_attribute :to_s, :name

  # Done this way so we get auto-closing of the File object
  # def yielding_upload_as_enumerable
  #   open(storage_path) do |file|
  #     if upload_content_type_xlsx?
  #       enumerator = Enumerator.new do |yielder|
  #         Oxcelix::Workbook.new(file).sheets[0].to_a.each do |row|
  #           yielder << row.map! { |cell| cell ? cell.to_fmt : '#N/A' }.join(',') + "\n"
  #         end
  #       end

  #       yield enumerator
  #     else
  #       yield file
  #     end
  #   end

  #   nil # for Run#with_run_status_tracking
  # end

  # private def upload_content_type_xlsx?
  #   upload.content_type == 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  # end

  def filesystem_storage?
    Paperclip::Attachment.default_options[:storage] == :filesystem
  end

  def storage_path
    # It's quite annoying that there's not 1 method that works for both filesystem and S3 storage
    filesystem_storage? ? upload.path : upload.url
  end

  # def update_upload_content!(content)
  #   old_file_name = upload_file_name
  #   self.upload = content
  #   self.upload_file_name = old_file_name

  #   save!
  # end

  # Not clear we'd want to do this even if we can, and right now the upload fields must be specified on create
  # def upload_as_io_writer

  # end

end
