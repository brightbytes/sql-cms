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

# For storing a reference to a CSV/TSV/any-tabularly-formatted-file on S3, for the purpose of loading/unloading data to/from the DB
class DataFile < ApplicationRecord

  auto_normalize

  # Validations

  validates :customer, :s3_region_name, :s3_bucket_name, :s3_file_name, presence: true

  FILE_TYPES = %w(import export).freeze

  validates :file_type, presence: true, inclusion: { in: FILE_TYPES }

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  validate :supplied_s3_url_is_not_hosed

  def supplied_s3_url_is_not_hosed
    errors.add(:supplied_s3_url, "must be provided") if supplied_s3_url.blank? && s3_bucket_name.blank? && s3_file_name.blank?
    errors.add(:supplied_s3_url, "is not a valid S3 URL") if supplied_s3_url.present? && s3_bucket_name.blank? && s3_file_name.blank?
  end

  # Callbacks

  before_validation :parse_supplied_s3_url

  def parse_supplied_s3_url
    if supplied_s3_url.present?
      http_match = %r{\Ahttp(?:s)?://s3-([-\w]+).amazonaws.com/([-\w]+)/(.{10,})\Z}.match(supplied_s3_url)
      if http_match
        self.s3_region_name = http_match[1]
        self.s3_bucket_name = http_match[2]
        file_path_and_name = http_match[3].split('/').reject(&:blank?)
        self.s3_file_path = file_path_and_name[0..-2].join('/') unless file_path_and_name.size == 1
        self.s3_file_name = file_path_and_name.last
      end
    end
  end

  # Associations

  belongs_to :customer, inverse_of: :data_files

  has_many :transforms, inverse_of: :data_file
  has_many :workflows, through: :transforms

  # Scopes



  # Instance Methods

  alias_attribute :to_s, :name

  def import?
    file_type == 'import'
  end

  def export?
    file_type == 'export'
  end

  attr_accessor :supplied_s3_url

  def s3_object(for_run = nil)
    return nil unless required_s3_fields_present?
    # FIXME - I'm not happy about how I did this method overloading.
    raise "You must supply a Run object for export files!" if export? && !for_run

    @s3_object ||
      begin
        s3_bucket = s3.bucket(s3_bucket_name)
        path = (export? ? "#{s3_file_path}/run_#{for_run.id}" : s3_file_path)
        @s3_object = s3_bucket.object("#{path}/#{s3_file_name}")
      end
  end

  def s3_presigned_url
    return false unless required_s3_fields_present?
    @s3_presigned_url ||= s3_object.presigned_url(:get) if s3_object.exists?
  end

  def s3_file_exists?
    import? && !!s3_presigned_url
  end

  def s3_public_url
    return false unless required_s3_fields_present?
    @s3_public_url ||= s3_object.public_url if s3_object.exists?
  end

  private def required_s3_fields_present?
    [s3_region_name, s3_bucket_name, s3_file_name].all?(&:present?)
  end

  # FIXME - ADD METHOD FOR PROVIDING AN UPLOAD STREAM SINK TO BE LOADED BY THE CLIENT FROM THE DB, TO CREATE AN S3 FILE THAT DOESN'T ALREADY EXIST
  #         THIS WILL REQUIRE ADDING AN EXTRA `"run_#{run.id}"` PARENT DIRECTORY TO THE SUPPLIED FILE NAME.  MEH.

  private

  def s3
    @s3 ||= Aws::S3::Resource.new(region: s3_region_name)
  end

  # Class Methods

end
