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

  # Associations

  # has_many :workflows, inverse_of: :customer
  # has_many :data_files, inverse_of: :customer

  # Scopes

  scope :sans_deleted, -> { where(deleted_at: nil) }

  # Callbacks



  # Instance Methods

  def slug=(val)
    super(val.presence && val.downcase.gsub(/\s+/, '_'))
  end

  def to_s
    slug
  end

  # Class Methods

  # Once seeding has been set up:
  # Define class-level predicates (e.g. Customer.duval?)
  # Define class-level loader methods (e.g. Customer.duval)


end
