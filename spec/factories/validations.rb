
FactoryGirl.define do

  factory :validation do
    sequence(:name) { |n| "Validation #{n}" }
    sequence(:sql) { |n| "SELECT #{n}" }

    trait :not_null do
      sql "SELECT id FROM :table_name WHERE :column_name IS NULL"
    end

    trait :presence do
      sql "SELECT id FROM :table_name WHERE (:column_name IS NULL OR trim(:column_name) = '')"
    end

    trait :uniqueness do
      sql "SELECT outer_table.id FROM :table_name outer_table WHERE (SELECT count(1) FROM :table_name inner_table WHERE inner_table.:column_name = outer_table.:column_name) > 1"
    end

    trait :fk do
      sql "SELECT id FROM :fk_table_name WHERE :fk_column_name IS NOT NULL AND NOT EXISTS (SELECT 1 FROM :pk_table_name WHERE :pk_table_name.:pk_column_name = :fk_table_name.:fk_column_name)"
    end

    trait :no_overlap do
      sql "SELECT first_alias.id FROM :table_name first_alias, :table_name second_alias WHERE first_alias.id <> second_alias.id AND ((first_alias.:low_column_name - second_alias.:high_column_name) * (second_alias.:low_column_name - first_alias.:high_column_name)) >= 0"
    end

    trait :greater_than_zero_validation do
      sql "SELECT id FROM :table_name WHERE :column_name <= 0"
    end

    trait :greater_than_or_equal_to_zero_validation do
      sql "SELECT id FROM :table_name WHERE :column_name < 0"
    end

    trait :not_empty_table do
      # There's a cleaner way to do this, but it's late, and I have a lot of other shit to do
      sql "SELECT TRUE AS :table_name_is_empty FROM nullif((SELECT count(1) FROM :table_name), 0) table_empty WHERE table_empty IS NULL"
    end
  end

  # TransformValidations

  factory :transform_validation do
    association :transform
    association :validation
    sequence(:params) { |n| { column_name: :stringy, table_name: "tmp_#{n}" } }

    trait :presence do
      association :validation, :presence
    end

    trait :not_null do
      association :validation, :not_null
    end

    trait :uniqueness do
      association :validation, :uniqueness
    end

    trait :fk do
      association :validation, :fk
    end

    trait :no_overlap do
      association :validation, :no_overlap
    end

    trait :greater_than_zero_validation do
      association :validation, :greater_than_zero_validation
    end

    trait :greater_than_or_equal_to_zero_validation do
      association :validation, :greater_than_or_equal_to_zero_validation
    end

  end
end
