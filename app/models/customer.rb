# == Schema Information
#
# Table name: public.customers
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
#  index_workflows_on_lowercase_slug  (lower((slug)::text)) UNIQUE
#

class Customer < ApplicationRecord

  include Concerns::SqlHelpers

  include Concerns::SqlSlugs

  acts_as_paranoid

  auto_normalize

  # Validations

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  # Associations

  has_many :workflows, inverse_of: :customer

  # Scopes

  scope :sans_deleted, -> { where(deleted_at: nil) }

  # Instance Methods

  def to_s
    slug
  end

  # Class Methods


end
