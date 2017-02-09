# == Schema Information
#
# Table name: public.transforms
#
#  id                       :integer          not null, primary key
#  name                     :string           not null
#  runner                   :string           default("Sql"), not null
#  workflow_id              :integer          not null
#  params                   :jsonb            not null
#  sql                      :text             not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  data_file_id             :integer
#  copied_from_transform_id :integer
#
# Indexes
#
#  index_transforms_on_copied_from_transform_id      (copied_from_transform_id)
#  index_transforms_on_data_file_id                  (data_file_id)
#  index_transforms_on_lowercase_name                (lower((name)::text)) UNIQUE
#  index_transforms_on_workflow_id_and_data_file_id  (workflow_id,data_file_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (copied_from_transform_id => transforms.id)
#  fk_rails_...  (data_file_id => data_files.id)
#  fk_rails_...  (workflow_id => workflows.id)
#

class Transform < ApplicationRecord

  include Concerns::ParamsHelpers

  auto_normalize except: :sql

  # Validations

  validates :sql, :workflow, presence: true

  RUNNERS = %w(RailsMigration AutoLoad CopyFrom Sql CopyTo Unload)

  validates :runner, presence: true, inclusion: { in: RUNNERS }

  validates :data_file, uniqueness: { scope: :workflow_id }, allow_nil: true

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  validate :params_not_null

  def params_not_null
    errors.add(:params, 'may not be null') unless params # {} is #blank?, hence this hair
  end

  # Callbacks



  # Associations

  belongs_to :workflow, inverse_of: :transforms

  has_one :customer, through: :workflow

  belongs_to :data_file, inverse_of: :transforms

  belongs_to :copied_from_transform, class_name: 'Transform', inverse_of: :copied_to_transforms
  has_many :copied_to_transforms, class_name: 'Transform', foreign_key: :copied_from_transform_id, inverse_of: :copied_from_transform

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
