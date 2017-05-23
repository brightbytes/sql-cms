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

  STEP_TYPES = %w(transform workflow_data_quality_report)

  validates :step_type, presence: true, inclusion: { in: STEP_TYPES }

  validates :run, presence: true, uniqueness: { scope: [:step_id, :step_index, :step_type] }

  # Callbacks



  # Associations

  belongs_to :run, inverse_of: :run_step_logs

  has_one :workflow_configuration, through: :run

  # Scopes

  scope :ordered_by_id, -> { order(:id) }

  scope :successful, -> { where(successful: true) }

  scope :failed, -> { where("step_exceptions IS NOT NULL OR step_validation_failures IS NOT NULL") }

  scope :non_erring, -> { where(step_exceptions: nil) }

  scope :erring, -> { where("step_exceptions IS NOT NULL") }

  scope :valid, -> { where(step_validation_failures: nil) }

  scope :invalid, -> { where("step_validation_failures IS NOT NULL") }

  scope :transforms, -> { where(step_type: 'transform') }

  scope :workflow_data_quality_reports, -> { where(step_type: 'workflow_data_quality_report') }

  # Instance Methods

  def failed?
    step_validation_failures.present? || step_exceptions.present?
  end

  def running_or_crashed?
    !successful? && !step_exceptions && !step_validation_failures
  end

  def step_name
    @step_name ||=
      begin
        field = (transform_log? ? :name : workflow_data_quality_report_log? ? :interpolated_name : nil)
        step_plan[field]
      end
  end

  def step_interpolated_sql
    @step_interpolated_sql ||= step_plan[:interpolated_sql]
  end

  def to_s
    step_name
  end

  def transform_log?
    step_type == 'transform'
  end

  def workflow_data_quality_report_log?
    step_type == 'workflow_data_quality_report'
  end

  def step_plan
    raise "No associated Run object!" unless run
    @step_plan ||=
      if transform_log?
        run.transform_plan(step_index: step_index, transform_id: step_id)
      elsif workflow_data_quality_report_log?
        run.workflow_data_quality_report_plan(step_id)
      end
  end

  def plan_source_step
    @plan_source_step ||=
      begin
        klass = (transform_log? ? Transform : workflow_data_quality_report_log? ? WorkflowDataQualityReport : nil)
        klass.find_by(id: step_plan[:id]) if klass
      end
  end

  # Run Step Logs are immutable after all Validations have been run, so this should be safe ... and it's quicker than creating a column for it.
  def duration_seconds
    end_time = (running_or_crashed? ? Time.zone.now : updated_at)
    end_time - created_at
  end

end
