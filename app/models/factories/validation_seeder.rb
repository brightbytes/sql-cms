# frozen_string_literal: true
module ValidationSeeder

  extend self

  def seed
    # I could have metaprogrammed this ... but I just want to get it done ...
    [
      Validation.non_null,
      Validation.presence,
      Validation.uniqueness,
      Validation.fk,
      Validation.inclusion,
      Validation.integer,
      Validation.integer_with_additional,
      Validation.greater_than,
      Validation.less_than,
      Validation.non_overlapping,
      Validation.percentage,
      Validation.between
    ]
  end

end
