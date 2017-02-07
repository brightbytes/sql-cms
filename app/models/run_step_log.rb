# == Schema Information
#
# Table name: public.run_step_logs
#
#  id          :integer          not null, primary key
#  run_id      :integer          not null
#  step_name   :string           not null
#  step_index  :integer          default(0), not null
#  step_id     :integer          default(0), not null
#  completed   :boolean          default(FALSE), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  step_errors :jsonb
#
# Indexes
#
#  index_run_step_logs_on_run_id  (run_id)
#
# Foreign Keys
#
#  fk_rails_...  (run_id => runs.id)
#

class RunStepLog < ApplicationRecord

  # Validations

  validates :run, :step_name, :step_index, :step_id, presence: true

  # Callbacks



  # Associations

  belongs_to :run, inverse_of: :run_step_logs

  # Scopes

  scope :ordered_by_id, -> { order(:id) }

  scope :completed, -> { where(completed: true) }

  scope :non_erring, -> { where(step_errors: nil) }

  scope :erring, -> { where("step_errors IS NOT NULL") }

  scope :successful, -> { completed.non_erring }

  # Instance Methods

  def successful?
    completed? && !step_errors
  end

  def running? # or, hung/terminated-abnormally, I suppose
    !completed? && !step_errors
  end

  def step
    return nil unless [step_name, step_index, step_id].all?(&:present)
    case step_name
    when 'create_schema'
      step_name
    when 'ordered_transform_groups'
      "#{step_name}[#{step_index}][#{step_id}]"
    when 'data_quality_reports'
      "#{step_name}[#{step_id}]"
    else
      raise "Unknown step_name: #{step_name}"
    end
  end
end
