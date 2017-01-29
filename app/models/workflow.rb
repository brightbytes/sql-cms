# == Schema Information
#
# Table name: public.workflows
#
#  id                      :integer          not null, primary key
#  name                    :string           not null
#  slug                    :string           not null
#  customer_id             :integer          not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  copied_from_workflow_id :integer
#
# Indexes
#
#  index_workflows_on_copied_from_workflow_id  (copied_from_workflow_id)
#  index_workflows_on_customer_id              (customer_id)
#  index_workflows_on_lowercase_name           (lower((name)::text)) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (copied_from_workflow_id => workflows.id)
#  fk_rails_...  (customer_id => customers.id)
#

class Workflow < ApplicationRecord

  # This class represents a particular configuration of an SQL Workflow at a particular point in time.
  # Its name and slug case-insensitively unique, here and in the DB.

  include Concerns::SqlHelpers

  include Concerns::SqlSlugs

  auto_normalize

  # Validations

  validates :customer, presence: true

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  validates :slug, presence: true, uniqueness: { case_sensitive: false }

  validate :slug_valid_sql_identifier

  def slug_valid_sql_identifier
    errors.add(:slug, "Is not a valid SQL identifier") unless slug =~ /^[a-z_]([a-z0-9_])*$/
  end

  # Associations

  belongs_to :customer, inverse_of: :workflows

  belongs_to :copied_from_workflow, class_name: 'Workflow', inverse_of: :copied_to_workflows
  has_many :copied_to_workflows, class_name: 'Workflow', foreign_key: :copied_from_workflow_id, inverse_of: :copied_from_workflow

  has_many :notifications, inverse_of: :workflow
  has_many :notified_users, through: :notifications, source: :user

  has_many :transforms, inverse_of: :workflow

  has_many :data_quality_reports, inverse_of: :workflow

  has_many :runs, inverse_of: :workflow

  # Instance Methods

  def to_s
    "#{customer.slug}_#{slug}".freeze
  end

end
