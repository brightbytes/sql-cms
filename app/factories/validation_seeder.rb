# frozen_string_literal: true
module ValidationSeeder

  extend self

  DIGIT_REGEXP = '^-?[[:digit:]]+$'

  def seed
    # I could have metaprogrammed this ... but I just want to get it done ...
    [non_null, presence, uniqueness, fk, inclusion, integer, integer_with_additional, greater_than, less_than, non_overlapping]
  end

  def non_null
    @not_null ||= Validation.where(name: 'Field Value IS NOT NULL').first_or_create!(
      immutable: true,
      sql: 'SELECT id FROM :table_name WHERE :column_name IS NULL'
    )
  end

  def presence
    @present ||= Validation.where(name: 'String Field Value is Present').first_or_create!(
      immutable: true,
      sql: "SELECT id FROM :table_name WHERE (:column_name <> '') IS NOT TRUE"
    )
  end

  def uniqueness
    @uniqueness ||= Validation.where(name: 'Field Value is Unique').first_or_create!(
      immutable: true,
      sql: 'SELECT :table_name.* FROM :table_name JOIN :table_name AS t ON :table_name.:column_name = t.:column_name AND :table_name.id != t.id'
    )
  end

  def fk
    @fk ||= Validation.where(name: 'Field Value is always a valid FK-Reference').first_or_create!(
      immutable: true,
      sql: "SELECT id FROM :fk_table_name WHERE :fk_column_name IS NOT NULL AND NOT EXISTS (SELECT 1 FROM :pk_table_name WHERE :pk_table_name.:pk_column_name = :fk_table_name.:fk_column_name)"
    )
  end

  def inclusion
    @inclusion ||= Validation.where(name: 'Field Value is included in a Set of Values').first_or_create!(
      immutable: true,
      sql: 'SELECT id FROM :table_name WHERE :column_name NOT IN (:allowed_values)'
    )
  end

  def integer
    @integer ||= Validation.where(name: 'Field Value is an Integer').first_or_create!(
      immutable: true,
      sql: "SELECT id FROM :table_name WHERE :column_name !~ '#{DIGIT_REGEXP}'"
    )
  end

  def integer_with_additional
    @integer_with_additional ||= Validation.where(name: 'Field Value is an Integer or one of the additional values').first_or_create!(
      immutable: true,
      sql: "SELECT id FROM :table_name WHERE :column_name !~ '#{DIGIT_REGEXP}' AND :column_name NOT IN (:extras)"
    )
  end

  def greater_than
    @greater_than ||= Validation.where(name: 'Field Value Greater Than').first_or_create!(
      immutable: true,
      sql: 'SELECT id from :table_name WHERE :column_name <= :value'
    )
  end

  def less_than
    @less_than ||= Validation.where(name: 'Field Value Less Than').first_or_create!(
      immutable: true,
      sql: 'SELECT id from :table_name WHERE :column_name >= :value'
    )
  end

  def non_overlapping
    @non_overlapping ||= Validation.where(name: "Field Ranges don't overlap").first_or_create!(
      immutable: true,
      sql: "SELECT first_alias.id FROM :table_name first_alias, :table_name second_alias WHERE first_alias.id <> second_alias.id AND ((first_alias.:low_column_name - second_alias.:high_column_name) * (second_alias.:low_column_name - first_alias.:high_column_name)) >= 0"
    )
  end

end
