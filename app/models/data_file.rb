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

# FIXME - Build a browser for files already on S3, using this example:
#          https://www.topdan.com/ruby-on-rails/aws-s3-browser.html
class DataFile < ActiveRecord::Base

  acts_as_paranoid

  auto_normalize

  # Validations

  validates :customer, :s3_bucket_name, :s3_file_name, presence: true

  validate :metadata_not_null

  def metadata_not_null
    errors.add(:metadata, 'may not be null') unless metadata # {} is #blank?, hence this hair
  end

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  # Callbacks



  # Associations

  belongs_to :customer, inverse_of: :data_files

  has_many :transforms, inverse_of: :data_file
  has_many :workflows, through: :transforms

  # Instance Methods

  alias_attribute :to_s, :name


end
