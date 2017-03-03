# == Schema Information
#
# Table name: public.run_step_logs
#
#  id                       :integer          not null, primary key
#  run_id                   :integer          not null
#  step_type                :string           not null
#  step_index               :integer          default(0), not null
#  step_id                  :integer          default(0), not null
#  successful               :boolean          default(FALSE), not null
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

  has_one :workflow, through: :run

  # Scopes

  scope :ordered_by_id, -> { order(:id) }

  scope :successful, -> { where(successful: true) }

  scope :failed, -> { where("step_exceptions IS NOT NULL OR step_validation_failures IS NOT NULL") }

  scope :non_erring, -> { where(step_exceptions: nil) }

  scope :erring, -> { where("step_exceptions IS NOT NULL") }

  scope :valid, -> { where(step_validation_failures: nil) }

  scope :invalid, -> { where("step_validation_failures IS NOT NULL") }

  scope :data_quality_reports, -> { where(step_type: 'data_quality_report') }

  scope :transforms, -> { where(step_type: 'transform') }

  # Instance Methods

  def failed?
    step_validation_failures.present? || step_exceptions.present?
  end

  def running_or_crashed?
    !successful? && !step_exceptions && !step_validation_failures
  end

  def step_name
    return nil unless run
    @step_name ||= step_plan[:name]
  end

  def step_interpolated_sql
    return nil unless run
    @step_interpolated_sql ||= step_plan[:interpolated_sql]
  end

  def to_s
    step_name
  end

  def step_plan
    return nil unless run
    @step_plan ||=
      if step_type == 'transform'
        run.transform_plan(step_index: step_index, transform_id: step_id)
      elsif step_type == 'data_quality_report'
        run.data_quality_report_plan(step_id)
      end
  end

  def likely_step
    return nil unless step_plan
    klass = (step_type == 'transform' ? Transform : DataQualityReport)
    klass.find_by(id: step_plan[:id])
  end

end
