# == Schema Information
#
# Table name: public.runs
#
#  id             :integer          not null, primary key
#  workflow_id    :integer          not null
#  creator_id     :integer          not null
#  schema_prefix  :string           not null
#  execution_plan :jsonb            not null
#  status         :string           default("unstarted"), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
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

  validates :workflow, :creator, :execution_plan, :status, :schema_prefix, presence: true

  # Callbacks

  before_validation :generate_schema_prefix, on: :create

  def generate_schema_prefix
    self.schema_prefix ||= "#{workflow}_run_".freeze
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

  def schema_name
    return unless schema_prefix.present?
    @schema_name ||= "#{schema_prefix}#{id}"
  end


  # MINOR_PHASES.each do |phase|
  #   class_eval %{
  #     def #{phase}?
  #       current_phase == '#{phase}'
  #     end
  #   }
  # end

  # def can_start?(phase)
  #   raise "Invalid phase: #{phase}" unless i = MINOR_PHASES.index(phase)
  #   i == 0 || current_phase == phase || current_phase == MINOR_PHASES[i - 1]
  # end

  # private def start_phase_if_startable!(start_phase)
  #   puke_if_unsaved

  #   return nil unless can_start?(start_phase)

  #   Rails.logger.info("Commencing phase #{start_phase} in schema #{schema_name} for Run with ID #{id} for Pipeline #{pipeline.name}")
  #   update_attribute(:current_phase, start_phase)
  # end

  # def run_all_in_phase!(run_serially:, phase_arel:, start_phase:, end_phase:)
  #   return nil unless start_phase_if_startable!(start_phase)

  #   if run_serially
  #     Run.all_succeeded?(phase_arel.map { |o| o.run(self) }).tap do |success|
  #       if success
  #         update_attribute(:current_phase, end_phase)
  #         Rails.logger.info("Completed phase #{start_phase}; now in phase #{end_phase} in schema #{schema_name} for Run with ID #{id} for Pipeline #{pipeline.name}")
  #       end
  #     end

  #     # else Fire off all these to run in parallel
  #   end
  # end

  # def ordered_statuses
  #   # Always reload, since this will be called after its Run object has been hanging around for a bit
  #   run_statuses(true).ordered_by_id.to_a
  # end

  # def succeeded?
  #   completed? && !failed?
  # end

  # def failed?
  #   !ordered_statuses.all?(&:step_successful?)
  # end

  # # This method is critically important, since it wraps the execution of every single step in the pipeline
  # def with_run_status_tracking(step)
  #   puke_if_unsaved
  #   raise "No block provided; really?!?" unless block_given?

  #   return nil unless step
  #   if run_status = RunStatus.find_by(run: self, step: step)
  #     return run_status.step_successful?
  #   end

  #   run_status = RunStatus.create!(run: self, step: step) # step_successful? defaults to false, of course

  #   begin
  #     if validation_failures_h = yield # A hash will only be returned for Validations that fail
  #       run_status.update_attribute(:step_errors, validation_failures_h)
  #       false # the return value, signifying failure
  #     else
  #       run_status.update_attribute(:step_successful, true) # the return value, signifying success
  #     end
  #   rescue StandardError => exception
  #     run_status.update_attribute(
  #       :step_errors,
  #       class_and_message: exception.inspect,
  #       backtrace: exception.backtrace.join("\n")
  #     )
  #     false # the return value, signifying failure
  #   end
  # end

  # # @return [Array<RunStatus>]
  # def run(run_serially = true)
  #   Rails.logger.info("Starting Run with ID #{id} for Pipeline #{pipeline.name}")

  #   if create_schema_and_tables!
  #     if run_serially
  #       upload_data_files! && add_indices! && validate_upload_phase! && # load
  #         initial_dimension_map! && dimension_map! && initial_fact_map! && fact_map! && validate_map_phase! && # map
  #         initial_reduce! && reducing! && validate_reduce_phase! && # reduce
  #         export_tables! # export
  #       # else
  #       # Fire off MasterJob, which initially fires off all CopyFrom transforms and then polls for each minor-phase's completion in turn; when a each minor-phase
  #       #  has ended, it initiates the next minor phase if there were no RunStatus failures.
  #     end
  #   end

  #   ordered_statuses
  # end

  # def create_schema_and_tables!
  #   return nil unless start_phase_if_startable!(CREATE_SCHEMA_PHASE)

  #   with_run_status_tracking(pipeline) { execute_ddl_in_schema(pipeline.ddl) }.tap do
  #     update_attribute(:current_phase, CREATED_SCHEMA_PHASE)
  #   end
  # end

  # def upload_data_files!(run_serially = true)
  #   run_all_in_phase!(run_serially: run_serially, phase_arel: pipeline_transforms.copy_from, start_phase: LOAD_PHASE, end_phase: LOADED_PHASE)
  # end

  # def add_indices!
  #   return nil unless start_phase_if_startable!(ADD_INDICES_PHASE)

  #   execute_ddl_in_schema(pipeline.indices_ddl) if pipeline.indices_ddl.present?
  #   update_attribute(:current_phase, ADDED_INDICES_PHASE)
  # end

  # def validate_upload_phase!(run_serially = true)
  #   run_all_in_phase!(run_serially: run_serially, phase_arel: pipeline_validations.load_phase, start_phase: LOAD_VALIDATION_PHASE, end_phase: LOAD_VALIDATED_PHASE)
  # end

  # def initial_dimension_map!(run_serially = true)
  #   run_all_in_phase!(run_serially: run_serially, phase_arel: pipeline_transforms.initial_dimension_map, start_phase: INITIAL_DIMENSION_MAP_PHASE, end_phase: INITIALLY_DIMENSION_MAPPED_PHASE)
  # end

  # def dimension_map!(run_serially = true)
  #   run_all_in_phase!(run_serially: run_serially, phase_arel: pipeline_transforms.dimension_map, start_phase: DIMENSION_MAP_PHASE, end_phase: DIMENSION_MAPPED_PHASE)
  # end

  # def initial_fact_map!(run_serially = true)
  #   run_all_in_phase!(run_serially: run_serially, phase_arel: pipeline_transforms.initial_fact_map, start_phase: INITIAL_FACT_MAP_PHASE, end_phase: INITIALLY_FACT_MAPPED_PHASE)
  # end

  # def fact_map!(run_serially = true)
  #   run_all_in_phase!(run_serially: run_serially, phase_arel: pipeline_transforms.fact_map, start_phase: FACT_MAP_PHASE, end_phase: FACT_MAPPED_PHASE)
  # end

  # def validate_map_phase!(run_serially = true)
  #   run_all_in_phase!(run_serially: run_serially, phase_arel: pipeline_validations.map_phase, start_phase: MAP_VALIDATION_PHASE, end_phase: MAP_VALIDATED_PHASE)
  # end

  # def initial_reduce!(run_serially = true)
  #   run_all_in_phase!(run_serially: run_serially, phase_arel: pipeline_transforms.initial_reduce, start_phase: INITIAL_REDUCE_PHASE, end_phase: INITIALLY_REDUCED_PHASE)
  # end

  # # To avoid confusion with Enum#map
  # def reducing!(run_serially = true)
  #   run_all_in_phase!(run_serially: run_serially, phase_arel: pipeline_transforms.reducing, start_phase: REDUCE_PHASE, end_phase: REDUCED_PHASE)
  # end

  # def validate_reduce_phase!(run_serially = true)
  #   run_all_in_phase!(run_serially: run_serially, phase_arel: pipeline_validations.reduce_phase, start_phase: REDUCE_VALIDATION_PHASE, end_phase: REDUCE_VALIDATED_PHASE)
  # end

  # # FIXME - CURRENTLY, THIS IS NOT IMPLEMENTED B/C WE MAY NOT WANT TO GO BACK OUT TO FILE: SEE COMMENT IN Run::PostgresSchema#copy_to_in_schema
  # def export_tables!(run_serially = true)
  #   run_all_in_phase!(run_serially: run_serially, phase_arel: pipeline_transforms.copy_to, start_phase: EXPORT_PHASE, end_phase: COMPLETED_PHASE)
  # end

  # def pp_ordered_statuses
  #   ordered_statuses.map do |run_status|
  #     if run_status.step_successful?
  #       "✓ #{run_status.step_type} - #{run_status.step_name}".colorize(:green)
  #     else
  #       [
  #         "✗ #{run_status.step_type} - #{run_status.step_name}".colorize(:red),
  #         run_status.step_errors.map { |key, value| [key, value, ""] }
  #       ]
  #     end
  #   end.flatten.join("\n")
  # end

  # class << self
  #   def all_succeeded?(arr)
  #     arr.all? { |result| result }
  #   end
  # end
end
