# == Schema Information
#
# Table name: public.run_step_logs
#
#  id                       :integer          not null, primary key
#  run_id                   :integer          not null
#  step_type                :string           not null
#  step_index               :integer          default(0), not null
#  step_id                  :integer          default(0), not null
#  completed                :boolean          default(FALSE), not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  step_validation_failures :jsonb
#  step_exceptions          :jsonb
#  step_result              :jsonb
#
# Indexes
#
#  index_run_step_logs_on_run_id_and_created_at  (run_id,created_at)
#
# Foreign Keys
#
#  fk_rails_...  (run_id => runs.id)
#

class RunStepLog < ApplicationRecord

  # Validations

  validates :step_index, :step_id, presence: true

  STEP_TYPES = %w(transform data_quality_report)

  validates :step_type, presence: true, inclusion: { in: STEP_TYPES }

  validates :run, presence: true, uniqueness: { scope: [:step_id, :step_index, :step_type] }

  # Callbacks



  # Associations

  belongs_to :run, inverse_of: :run_step_logs

  # Scopes

  scope :ordered_by_id, -> { order(:id) }

  scope :completed, -> { where(completed: true) }

  scope :non_erring, -> { where(step_exceptions: nil) }

  scope :erring, -> { where("step_exceptions IS NOT NULL") }

  scope :valid, -> { where(step_validation_failures: nil) }

  scope :invalid, -> { where("step_validation_failures IS NOT NULL") }

  scope :successful, -> { completed.non_erring.valid }

  scope :failed, -> { where("step_exceptions IS NOT NULL OR step_validation_failures IS NOT NULL") }

  # Instance Methods

  def successful?
    completed? && !step_exceptions && !step_validation_failures
  end

  def running? # or, hung/terminated-abnormally, I suppose
    !completed? && !step_exceptions && !step_validation_failures
  end

  def step_plan
    return nil unless run

  end

end
