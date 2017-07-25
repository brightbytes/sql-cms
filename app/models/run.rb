# == Schema Information
#
# Table name: public.runs
#
#  id                        :integer          not null, primary key
#  creator_id                :integer          not null
#  execution_plan            :jsonb            not null
#  status                    :string           default("unstarted"), not null
#  notification_status       :string           default("unsent"), not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  schema_name               :string
#  workflow_configuration_id :integer          not null
#
# Indexes
#
#  index_runs_on_creator_id                 (creator_id)
#  index_runs_on_workflow_configuration_id  (workflow_configuration_id)
#
# Foreign Keys
#
#  fk_rails_...  (creator_id => users.id)
#  fk_rails_...  (workflow_configuration_id => workflow_configurations.id)
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

  include Concerns::FinalizedRuntimeDuration

  auto_normalize

  # Validations

  validates :workflow_configuration, :creator, :execution_plan, :status, presence: true

  NOTIFICATION_STATUSES = %w(unsent sending sent)

  validates :notification_status, presence: true, inclusion: { in: NOTIFICATION_STATUSES }

  # Callbacks

  after_create :generate_schema_name

  private def generate_schema_name
    update_attribute(:schema_name, "#{workflow_configuration}_run_#{id}")
  end

  # From Run::PostgresSchema; consider removing to Observer or Service
  after_destroy :drop_schema_from_db

  private def drop_schema_from_db
    drop_schema(!use_redshift?)
  end

  # Associations

  has_many :run_step_logs, inverse_of: :run, dependent: :delete_all

  belongs_to :creator, class_name: 'User', inverse_of: :runs

  belongs_to :workflow_configuration, inverse_of: :runs

  has_one :customer, through: :workflow_configuration
  has_one :workflow, through: :workflow_configuration

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

  def execution_plan
    read_attribute(:execution_plan)&.with_indifferent_access # This should be automatic.  Grrr.
  end

  def execution_plan_object
    @execution_plan_object ||= ExecutionPlan.wrap(execution_plan)
  end

  delegate :transform_group, :transform_group_transform_ids, :transform_plan,
           :workflow_data_quality_reports, :workflow_data_quality_report_plan, :workflow_data_quality_report_ids,
           :use_redshift?, to: :execution_plan_object

  def transform_group_successful?(step_index)
    return nil if execution_plan.blank?
    ids = transform_group_transform_ids(step_index)
    run_step_logs.successful.transforms.where(step_index: step_index, step_id: ids).count == ids.size
  end

  def workflow_data_quality_reports_successful?
    return nil if execution_plan.blank?
    ids = workflow_data_quality_report_ids
    run_step_logs.successful.workflow_data_quality_reports.where(step_id: ids).count == ids.size
  end

  # This method is critically important, since it wraps the execution of every single step in the workflow
  def with_run_step_log_tracking(step_type:, step_index: 0, step_id: 0 )
    raise "No block provided; really?!?" unless block_given?
    return nil unless [step_type, step_index, step_id].all?(&:present?)

    run_step_log_args = { run: self, step_type: step_type, step_index: step_index, step_id: step_id }

    if run_step_log = RunStepLog.find_by(run_step_log_args)
      # We want this to return `true` even if the RunStepLog is still running so that we don't prematurely notify of failure
      return !run_step_log.failed?
    end

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

      # This hack undermines part of my (apparently bogus) theory about how to maintainably write Transforms.  Specifically, I *assumed* that modern DBs would provide
      #  an option to implement field-lock or at least column-lock semantics, since Oracle did a couple decades ago. However, neither Postgres nor Redshift do.
      # So, while I can still argue that writing Transforms on a column-by-column basis makes them easier to maintain because each Transform only concerns a single
      #  aspect of the data, I can no longer argue that any performance gains adhere.
      # Plus, I might not even have a leg to stand on as regards maintainability, since in some cases complex joins would need to be copy/pasted between Transforms
      #  that pertain to the same target table.
      if exception.message =~ /^PG::TRDeadlockDetected/
        run_step_log.destroy
        TransformJob.perform_later(run_id: id, step_index: step_index, step_id: step_id)
        true # the return value, signifying mu (non-failure, non-success, non-running_or_crashed - just don't send notifications)
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
        false # the return value, signifying failure
      end

    end
  end

  def notify_completed!
    return unless persisted?
    return unless execution_plan[:rfc_email_addresses_to_notify].present?
    # Atomically lock, to avoid dup notifications upon multiple failures
    update_count = Run.where(id: id, notification_status: 'unsent').update_all(notification_status: 'sending')
    if update_count == 1
      reload # to get new notification_status
      begin
        UserMailer.run_completed(self).deliver_later
      rescue
        update_attribute(:notification_status, 'unsent')
      end
      update_attribute(:notification_status, 'sent')
    end
  end

  # This is only useful in Development for debugging runner code, hence the lack of a test for it.
  # ... and, now it's no longer actually useful ... nuke soon ...
  # def nuke_failed_steps_and_rerun!
  #   if failed?
  #     run_step_logs.failed.delete_all
  #     update_attributes(notification_status: 'unsent', status: status.sub(/^started/, 'unstarted'))
  #     RunManagerJob.perform_later(id)
  #   end
  # end

  # This constant is copy/pasted from lib/tasks/db_setup.rake; DRY-up sometime
  def db_config
    @db_config ||= YAML.load(ERB.new(File.read("#{Rails.root}/config/database.yml")).result)[Rails.env]
  end

  def schema_dump
    common_switches = "--schema-only --schema=#{schema_name}"
    if Rails.env.production?
      infix ='$DATABASE_URL'
    else
      puts db_config['database']
      username, database, password = db_config["username"], db_config["database"], db_config["password"]
      infix = "--username #{username} --dbname #{database} --no-password"
      prefix = "PGPASSWORD=#{password}"
    end
    `#{prefix} pg_dump #{infix} #{common_switches}`
  end

end
