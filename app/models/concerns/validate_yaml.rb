module Concerns::ValidateYaml

  extend ActiveSupport::Concern

  def validate_yaml(attr, is_invalid)
    if is_invalid
      errors.delete(attr) # remove the `can't be blank` message
      errors.add(attr, "must be valid YAML")
    end
  end

end
