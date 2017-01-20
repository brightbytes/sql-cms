# == Schema Information
#
# Table name: workflows
#
#  id                      :integer          not null, primary key
#  name                    :string           not null
#  schema_base_name        :string           not null
#  dbms                    :string           default("postgres"), not null
#  customer_id             :integer          not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  copied_from_workflow_id :integer
#
# Indexes
#
#  index_workflows_on_copied_from_workflow_id     (copied_from_workflow_id)
#  index_workflows_on_customer_id                 (customer_id)
#  index_workflows_on_lowercase_name              (lower((name)::text)) UNIQUE
#  index_workflows_on_lowercase_schema_base_name  (lower((schema_base_name)::text)) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (copied_from_workflow_id => workflows.id)
#  fk_rails_...  (customer_id => customers.id)
#

class Workflow < ActiveRecord::Base

  # This class represents a particular configuration of an SQL Workflow at a particular point in time.
  # Its name and schema_base_name are case-insensitively unique, here and in the DB.

  include Concerns::SqlHelpers

  auto_normalize

  # Validations

  validates :customer, presence: true

  DBMS_TYPES = %w(postgres redshift).freeze

  validates :dbms, presence: true, inclusion: { in: DBMS_TYPES }

  validates :name, :schema_base_name, presence: true, uniqueness: { case_sensitive: false }

  # Callbacks



  # Associations

  belongs_to :customer, inverse_of: :workflows

  belongs_to :copied_from_workflow, class_name: 'Workflow', inverse_of: :copied_to_workflows
  has_many :copied_to_workflows, class_name: 'Workflow', foreign_key: :copied_from_workflow_id, inverse_of: :copied_from_workflow

  has_many :notifications, inverse_of: :workflow
  has_many :notified_users, through: :notifications, source: :user

  # has_many :transforms, inverse_of: :workflow

  # has_many :data_quality_checks, inverse_of: :workflow

  # has_many :runs, inverse_of: :workflow

  # Instance Methods

  def schema_base_name=(val)
    super(to_sql_identifier(val))
  end

  def to_s
    "#{customer.slug}_#{schema_base_name}".freeze
  end

end
