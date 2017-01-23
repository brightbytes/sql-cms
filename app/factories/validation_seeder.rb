# frozen_string_literal: true
module ValidationSeeder

  extend self

  DIGIT_REGEXP = '^-?[[:digit:]]+$'

  def seed
    Validation.where(name: 'Field Value IS NOT NULL').first_or_create!(
      immutable: true,
      sql: 'SELECT id FROM :table_name WHERE :column_name IS NULL'
    )

    Validation.where(name: 'Field Value is Present').first_or_create!(
      immutable: true,
      sql: "SELECT id FROM :table_name WHERE (:column_name IS NULL OR trim(:column_name) = '')" # There's probably a better idiom for this than the OR
    )

    Validation.where(name: 'Field Value is Unique').first_or_create!(
      immutable: true,
      sql: 'SELECT :table_name.* FROM :table_name JOIN :table_name AS t ON :table_name.:column_name = t.:column_name AND :table_name.id != t.id'
    )

    Validation.where(name: 'Field Value is always a valid FK-Reference').first_or_create!(
      immutable: true,
      sql: "SELECT id FROM :fk_table_name WHERE :fk_column_name IS NOT NULL AND NOT EXISTS (SELECT 1 FROM :pk_table_name WHERE :pk_table_name.:pk_column_name = :fk_table_name.:fk_column_name)"
    )

    Validation.where(name: 'Field Value is included in a Set of Values').first_or_create!(
      immutable: true,
      sql: 'SELECT id FROM :table_name WHERE :column_name NOT IN (:allowed_values)'
    )

    Validation.where(name: 'Field Value is an Integer').first_or_create!(
      immutable: true,
      sql: "SELECT id FROM :table_name WHERE :column_name !~ '#{DIGIT_REGEXP}'"
    )

    Validation.where(name: 'Field Value is an Integer or one of the additional values').first_or_create!(
      immutable: true,
      sql: "SELECT id FROM :table_name WHERE :column_name !~ '#{DIGIT_REGEXP}' AND :column_name NOT IN (:extras)"
    )

    Validation.where(name: 'Greater Than').first_or_create!(
      immutable: true,
      sql: 'SELECT id from :table_name WHERE :column_name <= :value'
    )

    Validation.where(name: 'Less Than').first_or_create!(
      immutable: true,
      sql: 'SELECT id from :table_name WHERE :column_name >= :value'
    )

    Validation.where(name: "Field Ranges don't overlap").first_or_create!(
      immutable: true,
      sql: "SELECT first_alias.id FROM :table_name first_alias, :table_name second_alias WHERE first_alias.id <> second_alias.id AND ((first_alias.:low_column_name - second_alias.:high_column_name) * (second_alias.:low_column_name - first_alias.:high_column_name)) >= 0"
    )
  end

  # These don't fit the pattern ^^ ... so they need to be Data Quality Checks.

  # def conditional_presence
  #   Validation.where(name: 'Conditional Presence').first_or_create!(
  #     immutable: true,
  #     sql: 'SELECT 1 FROM NULLIF((SELECT COUNT(1) FROM :table_name WHERE :column_name :where), 0) table_empty WHERE table_empty IS NULL'
  #   )
  # end

  # def not_empty_table
  #   Validation.where(name: 'Table not empty').first_or_create!(
  #     immutable: true,
  #     sql: "SELECT TRUE AS :table_name_is_empty FROM NULLIF((SELECT count(1) FROM :table_name), 0) table_empty WHERE table_empty IS NULL"
  #   )
  # end

end
