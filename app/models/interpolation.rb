# == Schema Information
#
# Table name: interpolations
#
#  id   :integer          not null, primary key
#  name :string           not null
#  slug :string           not null
#  sql  :string           not null
#
# Indexes
#
#  index_interpolations_on_lowercase_name  (lower((name)::text)) UNIQUE
#  index_interpolations_on_lowercase_slug  (lower((slug)::text)) UNIQUE
#

class Interpolation < ApplicationRecord

  auto_normalize except: :sql

  # Validations

  validates :sql, presence: true

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :slug, presence: true, uniqueness: { case_sensitive: false }

  validate :slug_validity

  def slug_validity
    if slug =~ /^[^a-z]/ || slug =~ /[^a-z0-9_]/ || slug =~ /_$/
      errors.add(:slug, "must start with a lowercase character, and otherwise be comprised only of lowercase characters, numbers, or underscores")
    end
  end

  # Callbacks

  before_destroy :bail_out_if_used

  def bail_out_if_used
    raise("You cannot nuke an Interpolation that's currently in use.") if used?
  end

  # Instance Methods

  def usage_count
    referencing_transforms.count + referencing_data_quality_reports.count
  end

  def used?
    usage_count > 0
  end

  def referencing_transforms
    Transform.where("sql LIKE '%:#{slug}%'")
  end

  def referencing_data_quality_reports
    DataQualityReport.where("sql LIKE '%:#{slug}%'")
  end


end
