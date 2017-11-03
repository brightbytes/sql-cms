# frozen_string_literal: true
module Concerns::ParamsHelpers

  extend ActiveSupport::Concern

  def params
    super&.with_indifferent_access
  end

  def params_yaml
    # We use the raw value to avoid the crap added by converting the hash to one with indifferent access in #params, ^^
    raw_params = read_attribute(:params)
    # We don't need no stinkin' document separator
    raw_params.to_yaml.sub("---\n", '') if raw_params.present?
  end

  def params_yaml=(val)
    self.params = (val.blank? ? {} : YAML.safe_load(val))
  rescue
    @params_yaml_invalid = true
  end

  included do
    validate :validate_yaml_for_params
  end

  def validate_yaml_for_params
    validate_yaml(:params, @params_yaml_invalid)
  end

  private def validate_yaml(attr, is_invalid)
    if is_invalid
      errors.delete(attr) # remove the `can't be blank` message
      errors.add(attr, "must be valid YAML")
    end
  end

end
