# frozen_string_literal: true
module Concerns::ImmutableCallbacks

  extend ActiveSupport::Concern

  module ClassMethods
    def immutable(*args)
      inviolate *args
    end

    def immutable_attribute_name(att)
      if att.present? && att.to_s != 'immutable'
        class_eval %Q{
          def immutable?
            #{att}?
          end
          def immutable_was
            #{att}_was
          end
          def immutable=(val)
            self.#{att} = val
          end
        }
      end
    end
  end

  include Concerns::InviolateCallbacks

  def read_only?
    immutable?
  end

  def prevent_destroy
    raise("You may not destroy an immutable #{self.class}") if immutable?
  end

  def prevent_update
    raise("You may not update an immutable #{self.class}") if immutable_was && changed?
  end
end
