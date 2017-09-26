# == Schema Information
#
# Table name: workflow_interpolations
#
#  id          :integer          not null, primary key
#  workflow_id :integer          not null
#  name        :string           not null
#  slug        :string           not null
#  sql         :string           not null
#
# Indexes
#
#  index_workflow_interpolations_on_lowercase_name_and_workflow_id  (lower((name)::text), workflow_id) UNIQUE
#  index_workflow_interpolations_on_lowercase_slug_and_workflow_id  (lower((slug)::text), workflow_id) UNIQUE
#  index_workflow_interpolations_on_workflow_id                     (workflow_id)
#
# Foreign Keys
#
#  fk_rails_...  (workflow_id => workflows.id)
#

class WorkflowInterpolation < ApplicationRecord

  auto_normalize except: :sql

  # Validations

  validates :sql, :workflow, presence: true

  validates :name, presence: true, uniqueness: { case_sensitive: false, scope: :workflow_id }
  validates :slug, presence: true, uniqueness: { case_sensitive: false, scope: :workflow_id }

  validate :slug_validity

  def slug_validity
    if slug =~ /^[^a-z]/ || slug =~ /[^a-z0-9_]/ || slug =~ /_$/
      errors.add(:slug, "must start with a lowercase character, and otherwise be comprised only of lowercase characters, numbers, or underscores")
    end
  end

  # Associations

  belongs_to :workflow, inverse_of: :workflow_interpolations

end
