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

  has_one :customer, through: :workflow

  has_many :transforms, through: :workflow

  has_many :data_quality_reports, through: :workflow

  # Instance Methods

  def to_s
    schema_name
  end

  def name
    to_s
  end

  def ordered_step_logs
    run_step_logs.reload.ordered_by_id.to_a # Always reload
  end

  def failed?
    run_step_logs.reload.failed.count > 0 # Always reload
  end

  def successful?
    status == 'finished'
  end

  def running_or_crashed?
    !failed? && !successful?
  end

  # This doesn't work ... and it just kills me!!!!!!
  # def step_exceptions
  #   read_attribute(:step_exceptions)&.map(&:with_indifferent_access) # This should be automatic.  Grrr.
  # end

  # def step_result
  #   read_attribute(:step_result)&.map(&:with_indifferent_access) # This should be automatic.  Grrr.
  # end

  # execution_plan helpers

  def execution_plan
    read_attribute(:execution_plan)&.with_indifferent_access # This should be automatic.  Grrr.
  end

  def transform_group(step_index)
    execution_plan[:ordered_transform_groups][step_index] if execution_plan.present?
  end

  def transform_group_transform_ids(step_index)
    transform_group(step_index)&.map { |h| h.fetch(:id, nil) }
  end

  def transform_plan(step_index:, transform_id:)
    transform_group(step_index)&.detect { |h| h[:id] == transform_id }&.deep_symbolize_keys
  end

  def transform_group_successful?(step_index)
    return nil if execution_plan.blank?
    ids = transform_group_transform_ids(step_index)
    run_step_logs.successful.where(step_type: 'transform', step_index: step_index, step_id: ids).count == ids.size
  end

  def data_quality_reports
    execution_plan[:data_quality_reports] if execution_plan.present?
  end

  def data_quality_report_plan(data_quality_report_id)
    data_quality_reports&.detect { |h| h[:id] == data_quality_report_id }&.symbolize_keys
  end

  def data_quality_report_ids
    data_quality_reports&.map { |h| h.fetch(:id, nil) }
  end

  # Yeah, o'er-long method name. Whoops.
  def data_quality_reports_successful?
    return nil if execution_plan.blank?
    ids = data_quality_report_ids
    run_step_logs.successful.where(step_type: 'data_quality_report', step_id: ids).count == ids.size
  end

  # This method is critically important, since it wraps the execution of every single step in the workflow
  def with_run_step_log_tracking(step_type:, step_index: 0, step_id: 0 )
    raise "No block provided; really?!?" unless block_given?
    return nil unless [step_type, step_index, step_id].all?(&:present?)

    run_step_log_args = { run: self, step_type: step_type, step_index: step_index, step_id: step_id }

    return nil if RunStepLog.find_by(run_step_log_args)

    run_step_log = RunStepLog.create!(run_step_log_args)

    begin

      result = yield

      if result.present?
        if step_result = result[:step_result].presence
          run_step_log.update_attribute(:step_result, step_result)
        end
        if step_validation_failures = result[:step_validation_failures].presence
          run_step_log.update_attribute(:step_validation_failures, step_validation_failures)
          return false # signifying failure
        end
      end

      run_step_log.update_attribute(:successful, true) # the return value, signifying success

    rescue Exception => exception

      # This hack is, quite frankly, utterly humiliating, since it undermines part of my (apparently bogus) theory about how to maintainably write Transforms.
      # Specifically, I *assumed* that modern DBs would provide an option to implement field-lock or at least column-lock semantics, since Oracle did a couple decades ago.
      # However, Postgres certainly doesn't, and Redshift doesn't appear to.
      # So, while I can still argue that writing Transforms on a column-by-column basis makes them easier to maintain because each Transform only concerns a single
      #  aspect of the data, I can no longer argue that any performance gains adhere.
      # Plus, I might not even have a leg to stand on as regards maintainability, since in some cases complex joins would need to be copy/pasted between Transforms
      #  that pertain to the same target table. FML ** 1,000,000,000
      if exception.message =~ /^PG::TRDeadlockDetected/
        run_step_log.destroy
        TransformJob.perform_later(run_id: id, step_index: step_index, step_id: step_id)
      else
        run_step_log.update_attribute(
          :step_exceptions,
          cause: exception.cause,
          # This doesn't always work ...
          class_and_message: exception.inspect,
          # ... hence this redundant bit
          message: exception.message,
          backtrace: Rails.backtrace_cleaner.clean(exception.backtrace)
        )
      end
      false # the return value, signifying failure

    end
  end
end
