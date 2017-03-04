# == Schema Information
#
# Table name: public.workflows
#
#  id          :integer          not null, primary key
#  name        :string           not null
#  slug        :string           not null
#  customer_id :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  template    :boolean          default(FALSE), not null
#
# Indexes
#
#  index_workflows_on_customer_id     (customer_id)
#  index_workflows_on_lowercase_name  (lower((name)::text)) UNIQUE
#
# Foreign Keys
#
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

  # Callbacks

  include Concerns::ImmutableCallbacks
  immutable :destroy
  immutable_attribute_name :template

  # Associations

  belongs_to :customer, inverse_of: :workflows

  has_many :notifications, inverse_of: :workflow, dependent: :delete_all
  has_many :notified_users, through: :notifications, source: :user

  has_many :transforms, inverse_of: :workflow, dependent: :destroy

  has_many :data_quality_reports, inverse_of: :workflow, dependent: :delete_all

  has_many :runs, inverse_of: :workflow, dependent: :destroy

  # Instance Methods

  def to_s
    "#{customer.slug}_#{slug}".freeze
  end

  accepts_nested_attributes_for :notified_users

  # The rest of this file is eligible for extraction to services.

  def run!(creator)
    plan = ActiveModelSerializers::SerializableResource.new(self).as_json
    runs.create!(creator: creator, execution_plan: plan).tap do |run|
      RunManagerJob.perform_later(run.id)
    end
  end

  # The following methods are used by the serializer

  def emails_to_notify
    notified_users.pluck(:email)
  end

  def rfc_email_addresses_to_notify
    notified_users.map(&:rfc_email_address)
  end

  def ordered_transform_groups
    unused_transform_ids = transforms.map(&:id)
    return [] if unused_transform_ids.empty?

    groups_arr = []

    independent_transforms = transforms.independent.to_a

    raise "Your alleged DAG is a cyclical graph because it has no leaf nodes." if independent_transforms.empty?

    groups_arr << independent_transforms
    unused_transform_ids -= independent_transforms.map(&:id)

    # Ah, my old nemesis, the while loop, ever insidiously scheming to iterate indefinitely.
    while unused_transform_ids.present?
      next_group = next_transform_group(transform_groups_thus_far: groups_arr, unused_transform_ids: unused_transform_ids)
      raise "Your alleged DAG is a cyclical graph because no transform group may be formed from the remaining transforms." if next_group.empty?
      groups_arr << next_group
      unused_transform_ids -= next_group.map(&:id)
    end

    groups_arr.map { |arr| Set.new(arr) }
  end

  private def next_transform_group(transform_groups_thus_far:, unused_transform_ids:)
    used_transform_ids = transform_groups_thus_far.flatten.map(&:id)
    joined_used_transform_ids = used_transform_ids.join(',')
    joined_unused_transform_ids = unused_transform_ids.join(',')
    transforms.
      where("id IN (#{joined_unused_transform_ids})").
      where("NOT EXISTS (SELECT 1 FROM transform_dependencies WHERE prerequisite_transform_id NOT IN (#{joined_used_transform_ids}) AND postrequisite_transform_id = transforms.id)").
      to_a
  end



end
