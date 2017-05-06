# frozen_string_literal: true

PaperTrail.config.track_associations = false

class PaperTrail::Version < ActiveRecord::Base
  include PaperTrail::VersionConcern

  if defined?(Rails::Console)
    PaperTrail.whodunnit = "#{`whoami`.strip}: console"
  elsif File.basename($PROGRAM_NAME) == "rake"
    PaperTrail.whodunnit = "#{`whoami`.strip}: rake #{ARGV.join ' '}"
  end

  # Associations

  belongs_to :user

  # Callbacks

  before_create :set_user_id

  def set_user_id
    self.whodunnit = whodunnit_before_type_cast.to_param
    uid = whodunnit.try(:to_i)
    self.user_id = uid unless uid == 0
  end

  # Instance Methods

  def changed_attributes
    (changeset.keys - ['updated_at']).join(', ')
  end
end

module PaperTrail::CleanupHook
  def self.included(base)
    base.prepend_after_action :cleanup_paper_trail_info
  end

  def cleanup_paper_trail_info
    ::PaperTrail.whodunnit = nil
    ::PaperTrail.controller_info = nil
  end
end

ActiveSupport.on_load(:action_controller) do
  include PaperTrail::CleanupHook
end
