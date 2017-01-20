module Concerns::SqlHelpers

  extend ActiveSupport::Concern

  def to_sql_identifier(s)
    self.class.to_sql_identifier(s)
  end


  module ClassMethods

    def to_sql_identifier(s)
      return nil unless s.present?
      s.to_s.downcase.gsub(/[^a-z0-9]+/, '_').sub(/^[^a-z_]/, '_')
    end

  end
end
