# == Schema Information
#
# Table name: public.run_step_logs
#
#  id          :integer          not null, primary key
#  run_id      :integer          not null
#  step_id     :integer          not null
#  step_type   :string           not null
#  step_name   :string           not null
#  completed   :boolean          default(FALSE), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  step_errors :jsonb
#
# Indexes
#
#  index_run_step_logs_on_run_id_and_step_id_and_step_type  (run_id,step_id,step_type) UNIQUE
#  index_run_step_logs_on_step_id_and_step_type             (step_id,step_type)
#
# Foreign Keys
#
#  fk_rails_...  (run_id => runs.id)
#

class RunStepLog < ApplicationRecord

  # Validations

  validates :step, :step_name, presence: true

  validates :run, presence: true, uniqueness: { scope: [:step_id, :step_type] }

  # Callbacks

  before_validation :maybe_set_step_name, on: :create

  def maybe_set_step_name
    self.step_name = step.try(:name)
  end

  # Associations

  belongs_to :run, inverse_of: :run_step_logs

  belongs_to :step, polymorphic: true

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

end
