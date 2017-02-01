# frozen_string_literal: true
module Concerns::ImmutableCallbacks

  extend ActiveSupport::Concern

  include Concerns::InviolateCallbacks

  included do
    inviolate :update, :destroy
  end

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
