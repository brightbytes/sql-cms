# == Schema Information
#
# Table name: public.run_step_logs
#
#  id                     :integer          not null, primary key
#  run_id                 :integer          not null
#  step_id                :integer          not null
#  step_type              :string           not null
#  step_name              :string           not null
#  completed_successfully :boolean          default(FALSE), not null
#  step_errors            :jsonb            not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
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

class RunStepLog < ActiveRecord::Base

  # Validations

  validates :step, :step_name, presence: true

  validates :run, presence: true, uniqueness: { scope: [:step_id, :step_type] }

  validate :step_errors_not_null

  def step_errors_not_null
    errors.add(:step_errors, 'may not be null') unless step_errors # {} is #blank?, hence this hair
  end

  # Callbacks

  before_validation :maybe_set_step_name

  def maybe_set_step_name
    self.step_name = step.try(:name)
  end

  # Associations

  belongs_to :run, inverse_of: :run_step_logs

  belongs_to :step, polymorphic: true

  # Scopes

  scope :ordered_by_id, -> { order(:id) }
end
