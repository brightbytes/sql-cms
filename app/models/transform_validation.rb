# frozen_string_literal: true
# == Schema Information
#
# Table name: public.transform_validations
#
#  id            :integer          not null, primary key
#  transform_id  :integer          not null
#  validation_id :integer          not null
#  params        :jsonb            not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_transform_validations_on_transform_id   (transform_id)
#  index_transform_validations_on_validation_id  (validation_id)
#
# Foreign Keys
#
#  fk_rails_...  (transform_id => transforms.id)
#  fk_rails_...  (validation_id => validations.id)
#

class TransformValidation < ApplicationRecord

  include Concerns::ParamsHelpers

  # Validations

  # Note that here, params can never be NULL/empty, unlike other JSONB columns.
  validates :validation, :transform, :params, presence: true

  # Associations

  with_options(inverse_of: :transform_validations) do |o|
    o.belongs_to :validation
    o.belongs_to :transform
  end

  # Instance Methods

  delegate :name, :sql, to: :validation

end
