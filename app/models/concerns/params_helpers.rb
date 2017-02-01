# frozen_string_literal: true
module Concerns::ParamsHelpers

  extend ActiveSupport::Concern

  def params_yaml
    params.to_yaml if params.present?
  end

  def params_yaml=(val)
    self.params = (val.blank? ? {} : YAML.load(val))
  end

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
