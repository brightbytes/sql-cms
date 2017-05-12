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

  def interpolated_name
    self.class.interpolate(string: name, params: params)
  end

  def interpolated_sql
    self.class.interpolate(string: sql, params: params)
  end

  def to_s
    interpolated_name
  end
  alias_method :display_name, :to_s

  module ClassMethods
    def interpolate(string:, params: nil)
      if params.present? && string.present?
        string.dup.tap do |string|
          params.each_pair do |k, v|
            v = v.map { |elm| connection.quote(elm) }.join(",") if v.is_a?(Array)
            # HMMMMM - This prevents matching of a key that is a subset of another key (:some_key would match :some_key_here),
            #           and it also prevents matching a colon in the middle of a string (unlikely case, to be sure),
            #           BUT, it may also prevent matching within a string when it's desired.  It's just that I can't think of when
            #           I would desire that, so screw it.
            string.gsub!(/(?<![a-zA-Z0-9_]):#{k}(?![a-zA-Z0-9_])/, v.to_s)
          end
          # FIXME - MAYBE ISSUE A WARNING HERE IF string CONTAINS AN UNINTERPOLATED PARAM. OR, HANDLE IN THE UI
        end
      else
        string
      end
    end
  end

end
