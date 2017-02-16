# frozen_string_literal: true
module Concerns::ParamsHelpers

  extend ActiveSupport::Concern

  include Concerns::ValidateYaml

  def params_yaml
    params.to_yaml if params.present?
  rescue
    # This line is probably unreachable
    @params_yaml_invalid = true
  end

  def params_yaml=(val)
    self.params = (val.blank? ? {} : YAML.load(val))
  rescue
    @params_yaml_invalid = true
  end

  included do
    validate :validate_yaml_for_params
  end

  def validate_yaml_for_params
    validate_yaml(:params, @params_yaml_invalid)
  end

  def interpolated_sql
    self.class.interpolate(sql: sql, params: params)
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
