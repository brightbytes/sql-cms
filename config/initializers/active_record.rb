# Put manifold AR customizations HERE :-P

# Force t.timestamps to always be null: false
module ActiveRecord
  module ConnectionAdapters
    class TableDefinition

      def timestamps_with_non_nullable(*args)
        options = args.extract_options!
        options[:null] = false
        timestamps_without_non_nullable(*args, options)
      end
      alias_method_chain :timestamps, :non_nullable

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
