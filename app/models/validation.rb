# frozen_string_literal: true
# == Schema Information
#
# Table name: public.validations
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  immutable  :boolean          default(FALSE), not null
#  sql        :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_validations_on_lowercase_name  (lower((name)::text)) UNIQUE
#

class Validation < ApplicationRecord

  # Validations are SQL Data Quality Checks run after Transforms with which they are associated, and validate that the transformed data isn't corrupt
  # A Validation returns the ID(s) of any record(s) that fail the validation

  auto_normalize

  # Validations

  validates :sql, presence: true

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  # Callbacks

  include Concerns::ImmutableCallbacks

  # Associations

  has_many :transform_validations, inverse_of: :validation, dependent: :destroy
  has_many :transforms, through: :transform_validations

  # Instance Methods

end
