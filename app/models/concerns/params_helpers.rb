# frozen_string_literal: true
module Concerns::ParamsHelpers

  extend ActiveSupport::Concern

  include Concerns::ValidateYaml

  def params
    super&.with_indifferent_access
  end

  def params_yaml
    # We use the raw value to avoid the crap added by converting the hash to one with indifferent access in #params, ^^
    raw_params = read_attribute(:params)
    raw_params.to_yaml if raw_params.present?
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
