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

  # Associations

end
