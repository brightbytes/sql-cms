# frozen_string_literal: true
# == Schema Information
#
# Table name: transform_validations
#
#  id            :integer          not null, primary key
#  transform_id  :integer          not null
#  validation_id :integer          not null
#  sql_params    :jsonb            not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_transform_validations_on_transform_validation_params  (transform_id,validation_id,sql_params) UNIQUE
#  index_transform_validations_on_validation_id                (validation_id)
#
# Foreign Keys
#
#  fk_rails_...  (transform_id => transforms.id)
#  fk_rails_...  (validation_id => validations.id)
#

class TransformValidation < ActiveRecord::Base

  include Concerns::SqlParamsInterpolator

  # Validations

  # Note that here, sql_params can never be {}, unlike other JSONB columns.
  validates :validation, :sql_params, presence: true

  # Not sure that I can just toss-in a JSONB column (that's a hash!) in a uniqueness constraint like this
  validates :transform, presence: true, uniqueness: { scope: [:validation_id, :sql_params] }

  # Associations

  with_options(inverse_of: :transform_validations) do |o|
    o.belongs_to :validation
    o.belongs_to :transform
  end

  # Instance Methods

  delegate :sql, to: :validation

  def name
    "Validation '#{validation.name}' for Transform '#{transform.name}'"
  end

  # FIXME - MOVE TO SERVICE LAYER
  # IMPORTANT: This will be how all Validations (that aren't PipelineValidations) are actually invoked: the delegated-to #run method shouldn't be called directly,
  #             which is why it is private
  # def run(run)
  #   run.with_run_status_tracking(self) do
  #     # All TransformValidations should return the IDs of the rows that fail validation
  #     if ids = validation.send(:run, run: run, validation_association: self).presence
  #       { ids_failing_validation: ids }
  #     end
  #   end
  # end

end
