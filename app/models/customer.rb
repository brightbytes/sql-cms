# == Schema Information
#
# Table name: customers
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  slug       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_customers_on_lowercase_name  (lower((name)::text)) UNIQUE
#  index_customers_on_lowercase_slug  (lower((slug)::text)) UNIQUE
#

class Customer < ApplicationRecord

  include Concerns::SqlHelpers

  include Concerns::SqlSlugs

  auto_normalize

  # Validations

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  # Associations

  has_many :workflow_configurations, inverse_of: :customer

  # Instance Methods

  def to_s
    slug
  end

  def used?
    workflow_configurations.count > 0
  end

  # Class Methods


end
