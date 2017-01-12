# frozen_string_literal: true
class EmailValidator < ActiveModel::EachValidator
  # If you're changing the regex here, please change it in app/assets/javascripts/directives/validate_email.js as well.
  EMAIL_REGEX = /\A(?:[a-z0-9._%+-]+)@(?:(?:[-a-z0-9]+\.)+[a-z]{2,})\z/i

  # rubocop:disable Metrics/ParameterLists
  def validate_each(record, attribute, value)
    if value.present?
      unless value =~ EMAIL_REGEX
        record.errors[attribute] << (options[:message] || "is not a valid email address")
      end
    end
  end
end
