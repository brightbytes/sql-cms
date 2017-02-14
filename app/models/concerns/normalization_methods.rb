# frozen_string_literal: true
# Provides methods to "normalize" String attributes (via squishing) before persistence to the DB
# This module is mixed in to ApplicationRecord to provide the normalization methods as declarations on AR model objects
module Concerns::NormalizationMethods

  extend ActiveSupport::Concern

  def base_normalize(val)
    val = val.to_s if val.is_a?(Symbol)
    val &&= val.squish
    val.presence
  end

  # Removes all non-numbers from a String containing numbers.  Most useful for phone number parsing.
  def numberize(val)
    val.to_s.gsub(/\D/, '') if val
  end

  module ClassMethods

    # Allows users to enumerate the atts to normalize in the given model; selects all String atts by default with no options.
    def auto_normalize(**options)
      addl_email_attrs = [options[:addl_email_attrs]].compact.flatten.map(&:to_sym)
      except_columns = [options.fetch(:except, [])].flatten.map(&:to_sym)
      columns.each do |c|
        n = c.name.to_sym
        next if except_columns.include?(n)
        if c.type.in?([:string, :text])
          (n == :email || n.in?(addl_email_attrs)) ? normalize_email_attr(n) : normalize_attr(n)
        end
      end
    rescue ActiveRecord::StatementInvalid => e
      # This is for rake one_ring, which pukes if att methods are defined when the DB doesn't exist yet
      raise unless e.message =~ /PG::UndefinedTable/
    # rescue PG::ConnectionBad => e
    #   # This is for Heroku, which is gagging on a fresh deploy
    #   raise unless e.message =~ /password authentication failed/
    end

    def normalize_attr(*attrs)
      attrs.each { |attr| define_method("#{attr}=") { |val| super(base_normalize(val)) } }
    end

    def normalize_email_attr(*attrs)
      attrs.each do |attr|
        define_method("#{attr}=") do |val|
          val = base_normalize(val)
          val.downcase! if val # this b/c i often forget to do case-insensitive email addr comparisons
          super(val)
        end
      end
    end

    def normalize_slug_attr(*attrs)
      attrs = [:slug] if attrs.empty?
      attrs.each do |attr|
        define_method("#{attr}=") do |val|
          super(base_normalize(val).try(:delete, ' ').try(:downcase))
        end
      end
    end

  end
end
