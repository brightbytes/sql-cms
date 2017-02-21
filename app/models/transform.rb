# == Schema Information
#
# Table name: public.transforms
#
#  id           :integer          not null, primary key
#  name         :string           not null
#  runner       :string           default("Sql"), not null
#  workflow_id  :integer          not null
#  sql          :text             not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  params       :jsonb
#  data_file_id :integer
#
# Indexes
#
#  index_transforms_on_data_file_id                  (data_file_id)
#  index_transforms_on_lowercase_name                (lower((name)::text)) UNIQUE
#  index_transforms_on_workflow_id_and_data_file_id  (workflow_id,data_file_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (data_file_id => data_files.id)
#  fk_rails_...  (workflow_id => workflows.id)
#

class Transform < ApplicationRecord

  include Concerns::ParamsHelpers

  auto_normalize except: :sql

  # Validations

  validates :sql, :workflow, presence: true

  validates :data_file, uniqueness: { scope: :workflow_id }, allow_nil: true

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  validates :runner, presence: true, inclusion: { in: RunnerFactory::RUNNERS }

  validate :data_file_type_vis_a_vis_runner

  def data_file_type_vis_a_vis_runner
    if runner.in?(RunnerFactory::DATA_FILE_RUNNERS)
      if data_file
        if runner.in?(RunnerFactory::IMPORT_DATA_FILE_RUNNERS)
          errors.add(:data_file, "must have a file_type of import for runners of type: #{RunnerFactory::JOINED_IMPORT_DATA_FILE_RUNNERS}") if data_file.export?
        elsif runner.in?(RunnerFactory::EXPORT_DATA_FILE_RUNNERS)
          errors.add(:data_file, "must have a file_type of export for runners of type: #{RunnerFactory::JOINED_EXPORT_DATA_FILE_RUNNERS}") if data_file.import?
        end
      else
        errors.add(:data_file, "is required for runners of type: #{RunnerFactory::JOINED_DATA_FILE_RUNNERS}")
      end
    else
      errors.add(:data_file, "should not be specified for runners of type #{RunnerFactory::JOINED_NON_DATA_FILE_RUNNERS}") if data_file
    end
  end

  # Callbacks



  # Associations

  belongs_to :workflow, inverse_of: :transforms

  has_one :customer, through: :workflow

  belongs_to :data_file, inverse_of: :transforms

  has_many :prerequisite_dependencies, class_name: 'TransformDependency', foreign_key: :postrequisite_transform_id, dependent: :delete_all
  has_many :prerequisite_transforms, through: :prerequisite_dependencies, source: :prerequisite_transform

  has_many :postrequisite_dependencies, class_name: 'TransformDependency', foreign_key: :prerequisite_transform_id, dependent: :delete_all
  has_many :postrequisite_transforms, through: :postrequisite_dependencies, source: :postrequisite_transform

  has_many :transform_validations, inverse_of: :transform, dependent: :delete_all
  has_many :validations, through: :transform_validations

  # Instance Methods

  accepts_nested_attributes_for :prerequisite_transforms

  # Any Transform that doesn't directly or indirectly have this Transform as a prerequisite is itself available as a prerequisite (and may already be such).
  # This is how we avoid cycles in the Transform Dependency graph.
  def available_prerequisite_transforms
    base_arel = Transform.where(workflow_id: workflow_id).order(:name)
    if new_record?
      base_arel.all
    else
      # This is grossly inefficient.  I tried to do it with SQL for the first level, and failed.  Oh well.  Refactor later.
      eligible_transforms = base_arel.where("id <> #{id}").all
      # Where's that graph DB when you need it?
      eligible_transforms.reject { |eligible_transform| already_my_postrequisite?(eligible_transform) }
    end
  end

  # Any Transform that doesn't directly or indirectly have this Transform as a prerequisite and is not already a prerequisite of this Transform
  #  is itself available as a new prerequisite.
  # Turns out we may not need this method; only #available_prerequisite_transforms is in fact necessary
  def available_unused_prerequisite_transforms
    available_prerequisite_transforms.reject { |eligible_transform| already_my_prerequisite?(eligible_transform) }
  end

  private

  def already_my_postrequisite?(transform)
    dependents = transform.prerequisite_transforms
    return false if dependents.empty?
    return true if dependents.include?(self)
    dependents.any? { |dependent_transform| already_my_postrequisite?(dependent_transform) }
  end

  def already_my_prerequisite?(transform)
    dependents = transform.postrequisite_transforms
    return false if dependents.empty?
    return true if dependents.include?(self)
    dependents.any? { |dependent_transform| already_my_prerequisite?(dependent_transform) }
  end

end
