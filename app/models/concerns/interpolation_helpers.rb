# frozen_string_literal: true
module Concerns::InterpolationHelpers

  extend ActiveSupport::Concern

  # This should probably go away: interpolating name fields is useless b/c name fields (quite reasonably) have uniqueness constraints on them
  def interpolated_name
    self.class.interpolate(string: name, params: params, quote_arrays: false)
  end

  def interpolated_sql
    self.class.interpolate(string: sql, params: params, quote_arrays: true, use_global_interpolations: true)
  end

  def to_s
    interpolated_name
  end
  alias_method :display_name, :to_s

  module ClassMethods
    def interpolate(string:, params: nil, quote_arrays: true, use_global_interpolations: false)
      return string if string.blank?

      # This occurs first so that it may contain interpolation vars.
      string = handle_global_imputations(string) if use_global_interpolations

      if params.present?
        string = string.dup.tap do |s|
          params.each_pair do |k, v|
            v = coerce_param_value(v, quote_arrays)
            # HMMMMM - This prevents matching of a key that is a subset of another key (:some_key would match :some_key_here),
            #           and it also prevents matching a colon in the middle of a string (unlikely case, to be sure),
            #           BUT, it may also prevent matching within a string when it's desired, hence the removal of the _ from the negative lookbehind/lookahead
            # s.gsub!(/(?<![a-zA-Z0-9_]):#{k}(?![a-zA-Z0-9_])/, v)
            s.gsub!(/(?<![a-zA-Z0-9]):#{k}(?![a-zA-Z0-9])/, v)
          end
        end
      end

      # FIXME - MAYBE ISSUE A WARNING HERE IF string CONTAINS AN UNINTERPOLATED PARAM. OR, HANDLE IN THE UI

      string
    end

    private

    def handle_global_imputations(string)
      # This strikes me as inefficent.  Oh well.
      global_interpolations = SqlSnippet.pluck(:slug, :sql).to_h
      if global_interpolations.present?
        string = string.dup.tap do |s|
          global_interpolations.each_pair do |k, v|
            s.gsub!(/(?<![a-zA-Z0-9]):#{k}:/, v)
          end
        end
      end
      string
    end

    def coerce_param_value(v, quote_arrays)
      if v.is_a?(Array)
        # We assume here that the intention is for the array to be used as values, e.g. for a SQL `IN` clause.
        v = v.map { |elm| connection.quote(elm.to_s) } if quote_arrays
        v.join(", ")
      else
        # ... whereas, here the intention most of the time is for the value to be used as a table name or column name,
        #     so we only escape, and don't enclose in quotes
        connection.quote_string(v.to_s)
      end
    end
  end

end
