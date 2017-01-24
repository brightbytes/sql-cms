# Annotate HACKS, to fix the issue annotating FKs and Indexes
# The real bug is in ActiveRecord::ConnectionAdapters::PostgreSQLAdapter in the `indexes` and `foreign_key` methods, but I need to get this done,
#  and my attempts to fix it in Rails failed.

if Rails.env.development?

  def AnnotateModels.retrieve_indexes_from_table(klass)
    # This is the patched line:
    table_name = klass.table_name.sub('public.', '')
    return [] unless table_name

    indexes = klass.connection.indexes(table_name)
    return indexes if indexes.any? || !klass.table_name_prefix

    # Try to search the table without prefix
    table_name.to_s.slice!(klass.table_name_prefix)
    klass.connection.indexes(table_name)
  end

  def AnnotateModels.get_foreign_key_info(klass, options = {})
    fk_info =
      if options[:format_markdown]
        "#\n# ### Foreign Keys\n#\n"
      else
        "#\n# Foreign Keys\n#\n"
      end

    return '' unless klass.connection.respond_to?(:supports_foreign_keys?) &&
                     klass.connection.supports_foreign_keys? && klass.connection.respond_to?(:foreign_keys)

    # This is the patched line:
    foreign_keys = klass.connection.foreign_keys(klass.table_name.sub('public.', ''))
    return '' if foreign_keys.empty?

    format_name = ->(fk) { fk.name.gsub(/(?<=^fk_rails_)[0-9a-f]{10}$/, '...') }

    max_size = foreign_keys.map(&format_name).map(&:size).max + 1
    foreign_keys.sort_by {|fk| [format_name.call(fk), fk.column]}.each do |fk|
      ref_info = "#{fk.column} => #{fk.to_table}.#{fk.primary_key}"
      constraints_info = ''
      constraints_info += "ON DELETE => #{fk.on_delete} " if fk.on_delete
      constraints_info += "ON UPDATE => #{fk.on_update} " if fk.on_update
      constraints_info.strip!

      fk_info <<
        if options[:format_markdown]
          sprintf("# * `%s`%s:\n#     * **`%s`**\n", format_name.call(fk), constraints_info.blank? ? '' : " (_#{constraints_info}_)", ref_info)
        else
          sprintf("#  %-#{max_size}.#{max_size}s %s %s", format_name.call(fk), "(#{ref_info})", constraints_info).rstrip + "\n"
        end
    end

    fk_info
  end

end
