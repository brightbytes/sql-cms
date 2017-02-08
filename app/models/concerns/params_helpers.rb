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
    self.class.interpolated(sql: sql, params: params)
  end

  module ClassMethods
    def interpolate(sql:, params: nil)
      if params.present?
        sql.dup.tap do |sql|
          params.each_pair do |k, v|
            sql.gsub!(":#{k}", v.to_s)
          end
        end
      else
        sql
      end
    end
  end

end
