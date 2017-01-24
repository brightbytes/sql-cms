# == Schema Information
#
# Table name: public.transform_dependencies
#
#  id                         :integer          not null, primary key
#  prerequisite_transform_id  :integer          not null
#  postrequisite_transform_id :integer          not null
#  created_at                 :datetime         not null
#
# Indexes
#
#  index_transform_dependencies_on_prerequisite_transform_id  (prerequisite_transform_id)
#  index_transform_dependencies_on_unique_transform_ids       (postrequisite_transform_id,prerequisite_transform_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (postrequisite_transform_id => transforms.id)
#  fk_rails_...  (prerequisite_transform_id => transforms.id)
#

class TransformDependency < ActiveRecord::Base

  # Validations

  validates :postrequisite_transform, :prerequisite_transform, presence: true

  validates :prerequisite_transform, uniqueness: { scope: :postrequisite_transform_id }

  # Associations

  belongs_to :postrequisite_transform, class_name: 'Transform', inverse_of: :prerequisite_dependencies
  belongs_to :prerequisite_transform, class_name: 'Transform', inverse_of: :postrequisite_dependencies

end
