# frozen_string_literal: true
module Concerns::SqlSlugs

  extend ActiveSupport::Concern

  included do
    validates :slug, presence: true, uniqueness: { case_sensitive: false }

    validate :slug_valid_sql_identifier

    # Callbacks

    before_validation :maybe_set_slug_from_name, if: :new_record?
  end

  def slug_valid_sql_identifier
    errors.add(:slug, "Is not a valid SQL identifier") unless slug =~ /^[a-z_]([a-z0-9_])*$/
  end

  def maybe_set_slug_from_name
    self.slug = name unless slug.present?
  end

  def slug=(val)
    super(to_sql_identifier(val))
  end

end
