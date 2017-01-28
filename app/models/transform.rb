# == Schema Information
#
# Table name: public.transforms
#
#  id                            :integer          not null, primary key
#  name                          :string           not null
#  runner                        :string           not null
#  workflow_id                   :integer          not null
#  params                        :jsonb            not null
#  sql                           :text             not null
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  transcompiled_source          :text
#  transcompiled_source_language :string
#  data_file_id                  :integer
#  copied_from_transform_id      :integer
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

  include Concerns::SqlParamsInterpolator

  auto_normalize

  # Validations

  validates :runner, :sql, :workflow, presence: true

  validates :data_file, uniqueness: { scope: :workflow_id }, allow_nil: true

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  validate :params_not_null

  def params_not_null
    errors.add(:params, 'may not be null') unless params # {} is #blank?, hence this hair
  end

  # Callbacks



  # Associations

  belongs_to :workflow, inverse_of: :transforms

  belongs_to :data_file, inverse_of: :transforms

  belongs_to :copied_from_transform, class_name: 'Transform', inverse_of: :copied_to_transforms
  has_many :copied_to_transforms, class_name: 'Transform', foreign_key: :copied_from_transform_id, inverse_of: :copied_from_transform

  has_many :prerequisite_dependencies, class_name: 'TransformDependency', foreign_key: :postrequisite_transform_id
  has_many :prerequisite_transforms, through: :prerequisite_dependencies, source: :prerequisite_transform

  has_many :postrequisite_dependencies, class_name: 'TransformDependency', foreign_key: :prerequisite_transform_id
  has_many :postrequisite_transforms, through: :postrequisite_dependencies, source: :postrequisite_transform

  has_many :transform_validations, inverse_of: :transform, dependent: :destroy
  has_many :validations, through: :transform_validations

  # Instance Methods

  # FIXME - MOVE TO SERVICE LAYER AS Runner, WITH strategy classes
  #
  # From PipelineTransform
  # def run(run)
  #   run.with_run_status_tracking(self) { transform.send(:run, run: run, pipeline_transform: self) } &&
  #     Run.all_succeeded?(transform_validations.map { |transform_validation| transform_validation.run(run) })
  # end
  # This is private because Transforms should always be invoked through PipelineTransform#run (which delegates to this) since it adds run status tracking
  # private def run(run:, pipeline_transform:)
  #   # This default implementation works for everything except CopyFrom and CopyTo, which both require interaction with an IO object
  #   run.execute_in_schema(pipeline_transform.interpolated_dml)
  # end

end
