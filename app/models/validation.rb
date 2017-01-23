# frozen_string_literal: true
# == Schema Information
#
# Table name: validations
#
#  id                            :integer          not null, primary key
#  name                          :string           not null
#  immutable                     :boolean          default(FALSE), not null
#  sql                           :text             not null
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  transcompiled_source          :text
#  transcompiled_source_language :string
#
# Indexes
#
#  index_validations_on_lowercase_name  (lower((name)::text)) UNIQUE
#

class Validation < ActiveRecord::Base

  # Validations are Data Quality Checks for specific Transforms

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

  # FIXME - MOVE TO SERVICE LAYER
  # This is private because Validations should always be invoked through TransformValidation#run or PipelineValidation#run (both of which delegate to this)
  #  since those methods add run status tracking
  # private def run(run:, validation_association:, query_method: :select_values_in_schema)
  #   run.send(query_method, validation_association.interpolated_sql)
  # end

end
