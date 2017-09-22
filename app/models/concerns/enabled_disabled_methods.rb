module Concerns::EnabledDisabledMethods

  extend ActiveSupport::Concern

  included do
    scope :enabled, -> { where(enabled: true) }
    scope :disabled, -> { where(enabled: false) }
  end

  def disabled?
    !enabled?
  end

  def disabled
    !enabled?
  end

  def disabled=(val)
    if respond_to?(:enabled_at)
      self.enabled_at = (val ? nil : Time.current.getutc)
    end
    self.enabled = !val
  end

  def enabled=(val)
    if respond_to?(:enabled_at)
      self.enabled_at = (val ? Time.current.getutc : nil)
    end
    super
  end

  def enable
    self.enabled = true
  end

  def disable
    self.enabled = false
  end

  def enable!
    enable
    save
  end

  def disable!
    disable
    save
  end

end
