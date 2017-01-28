# Put manifold AR customizations HERE :-P

# Force t.timestamps to always be null: false

module ForceTimestampsNonNullable

  def timestamps(*args)
    options = args.extract_options!
    options[:null] = false
    super(*args, options)
  end

end

module ActiveRecord
  module ConnectionAdapters
    class TableDefinition
      prepend ForceTimestampsNonNullable
    end
  end
end
