# frozen_string_literal: true
module Concerns::SqlParamsInterpolator

  extend ActiveSupport::Concern

  def interpolated_sql
    if params.present?
      sql.dup.tap do |sql|
        params.each_pair do |k, v|
          sql.gsub!(":#{k}", v)
        end
      end
    else
      sql
    end
  end
end
