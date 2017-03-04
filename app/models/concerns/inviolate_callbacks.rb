# frozen_string_literal: true
# This module is intended to prevent common mistakes attempting to write to some of the tables in your application
# It is *not* comprehensive: you could still get around it via a connection.execute()
# If it is critically important that a model not be written-to, you should configure your DB connection accordingly, using GRANTs
module Concerns::InviolateCallbacks

  extend ActiveSupport::Concern

  # FIXME: ensure self.class interpolates at the right time with the right `self`.
  module ClassMethods
    def inviolate(*args, **keywords)
      args.map(&:to_sym).uniq.each do |m|
        callback = :"before_#{m}"
        callback_m = :"prevent_#{m}"
        # I've been on the fence about including keywords, since it would be a hassle to fit them in below ... sigh.  Not going to deal with it now.
        send(callback, callback_m, **keywords) if respond_to?(callback)

        if m == :destroy
          class_eval %[
            def delete
              raise("You may not bypass callbacks to delete a #{self.class}.")
            end
          ]

          instance_eval %[
            def delete # Not sure this one is necessary
              raise("You may not bypass callbacks to delete a #{self}.")
            end
            def delete_all
              raise("You may not bypass callbacks to delete all the #{self} that exist, since some may be inviolate.")
            end
          ]
        end

        if m == :update
          class_eval %[
            def update_column(*args)
              raise("You may not bypass callbacks to update a #{self.class}.")
            end
          ]

          instance_eval %[
            def update_all(updates)
              raise("You may not bypass callbacks to update all the #{self} that exist, since some may be inviolate.")
            end
          ]
        end
      end
    end
  end

  # Override these methods for per-instance conditional modification

  def prevent_destroy
    raise("You may not destroy a #{self.class}")
  end

  def prevent_create
    raise("You may not create a #{self.class}")
  end

  def prevent_update
    raise("You may not update a #{self.class}")
  end
end
