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

ActiveRecord::Base.class_eval do

  # include Ext::InviolateCallbacks

  include Concerns::NormalizationMethods

  # include Rails.application.routes.url_helpers # neeeded for _path helpers to work in models
  # def admin_link # for Paper Trail
  #   nil
  # end

end
