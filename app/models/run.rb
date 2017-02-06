# == Schema Information
#
# Table name: public.runs
#
#  id             :integer          not null, primary key
#  workflow_id    :integer          not null
#  creator_id     :integer          not null
#  execution_plan :jsonb            not null
#  status         :string           default("unstarted"), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  schema_name    :string
#
# Indexes
#
#  index_runs_on_creator_id   (creator_id)
#  index_runs_on_workflow_id  (workflow_id)
#
# Foreign Keys
#
#  fk_rails_...  (creator_id => users.id)
#  fk_rails_...  (workflow_id => workflows.id)
#

# The point of this class is to execute a Workflow in an isolated namespace (think "separate DB context")
class Run < ApplicationRecord

  # You gotta Run, Run, Run, Run, Run
  # Take a drag or two.
  # Run, Run, Run, Run, Run,
  # Gypsy death and you
  # Say what to do.

  # Consider pulling out into Service layer
  include Run::PostgresSchema

  auto_normalize

  # Validations

  validates :workflow, :creator, :execution_plan, :status, presence: true

  # Callbacks

  after_create :generate_schema_name

  def generate_schema_name
    update_attribute(:schema_name, "#{workflow}_run_#{id}")
  end

  # From Run::PostgresSchema; consider removing to Observer or Service
  after_destroy :drop_schema

  # Associations

  has_many :run_step_logs, inverse_of: :run, dependent: :delete_all

  belongs_to :creator, class_name: 'User', inverse_of: :runs

  belongs_to :workflow, inverse_of: :runs

  has_many :transforms, through: :workflow

  has_many :data_quality_reports, through: :workflow

  # Instance Methods

  def to_s
    schema_name
  end

  def name
    to_s
  end

  def execution_plan
    read_attribute(:execution_plan)&.with_indifferent_access # This should be automatic.  Grrr.
  end

  def ordered_step_logs
    run_step_logs.reload.ordered_by_id.to_a # Always reload
  end

  # FIXME: This should be in a view-related file.  Not bothering to test it until I've decided where it lands.
  def pp_ordered_step_logs
    ordered_step_logs.map do |step_log|
      if run_step_log.successful?
        "✓ #{run_step_log.step_type} - #{run_step_log.step_name}".colorize(:green)
      elsif run_step_log.running?
        ". #{run_step_log.step_type} - #{run_step_log.step_name}".colorize(:yellow)
      else
        [
          "✗ #{run_step_log.step_type} - #{run_step_log.step_name}".colorize(:red),
          run_step_log.step_errors.map { |key, value| [key, value, ""] }
        ]
      end
    end.flatten.join("\n")
  end

  def failed?
    run_step_logs.reload.where("step_errors IS NOT NULL").count > 0 # Always reload
  end

  def transform_group(group_index)
    execution_plan[:ordered_transform_groups][group_index] if execution_plan.present?
  end

  def transform_group_transform_ids(group_index)
    transform_group(group_index)&.map { |h| h.fetch(:id, nil) }
  end

  def transform_group_successfully_completed?(group_index)
    return nil if execution_plan.blank?
    ids = transform_group_transform_ids(group_index)
    run_step_logs.successful.where(step_id: ids, step_type: 'Transform').count == ids.size
  end

  def data_quality_reports
    execution_plan[:data_quality_reports] if execution_plan.present?
  end

  def data_quality_report_ids
    data_quality_reports&.map { |h| h.fetch(:id, nil) }
  end

  # Yeah, o'er-long method name. Whoops.
  def data_quality_reports_successfully_completed?
    return nil if execution_plan.blank?
    ids = data_quality_report_ids
    run_step_logs.successful.where(step_id: ids, step_type: 'DataQualityReport').count == ids.size
  end

  # This method is critically important, since it wraps the execution of every single step in the workflow
  # Arguably, it should be extracted from this file.  Refactor some sunny day.
  def with_run_step_log_tracking(step)
    raise "No block provided; really?!?" unless block_given?

    return nil unless step

    # FIXME - MAY WANT A TRANSACTION FROM HERE ON DOWN, TO PREVENT THE RACE CONDITION
    if run_step_log = RunStepLog.find_by(run: self, step: step)
      return run_step_log.successful?
    end

    run_step_log = RunStepLog.create!(run: self, step: step)

    begin

      if validation_failures_h = yield # A hash will only be returned for Validations that fail
        run_step_log.update_attribute(:step_errors, validation_failures_h)
        false # the return value, signifying failure
      else
        run_step_log.update_attribute(:completed, true) # the return value, signifying success
      end

    rescue StandardError => exception

      run_step_log.update_attribute(
        :step_errors,
        class_and_message: exception.inspect,
        backtrace: exception.backtrace.join("\n")
      )
      false # the return value, signifying failure

    end
  end
end
