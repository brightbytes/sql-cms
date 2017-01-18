# == Schema Information
#
# Table name: customers
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  slug       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  deleted_at :datetime
#
# Indexes
#
#  index_customers_on_lowercase_name  (lower((name)::text)) UNIQUE
#  index_customers_on_lowercase_slug  (lower((slug)::text)) UNIQUE
#

class Customer < ActiveRecord::Base

  acts_as_paranoid

  auto_normalize

  # Validations

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  validates :slug, presence: true, uniqueness: { case_sensitive: false }

  validate :slug_not_updatable, if: :slug_changed?

  def slug_not_updatable
    errors.add(:slug, "is not updatable once set") if slug_was.present?
  end

  validate :slug_valid_sql_identifier

  def slug_valid_sql_identifier
    errors.add(:slug, "Is not a valid SQL identifier") unless slug =~ /^[a-z_]([a-z0-9_])*$/
  end

  # Associations

  # has_many :workflows, inverse_of: :customer
  has_many :data_files, inverse_of: :customer

  # Scopes

  scope :sans_deleted, -> { where(deleted_at: nil) }

  # Callbacks

  before_validation :maybe_set_slug_from_name, if: :new_record?

  def maybe_set_slug_from_name
    self.slug = name unless slug.present?
  end

  # Instance Methods

  def slug=(val)
    super(val.presence && val.downcase.gsub(/[^a-z0-9]+/, '_'))
  end

  def to_s
    slug
  end

  # Class Methods

  # Once seeding has been set up, maybe:
  # Define class-level predicates (e.g. Customer.duval?)
  # Define class-level loader methods (e.g. Customer.duval)


end
