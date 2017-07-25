class ApplicationRecord < ActiveRecord::Base

  self.abstract_class = true

  has_paper_trail

  include Concerns::NormalizationMethods

  # include Ext::InviolateCallbacks

  # include Rails.application.routes.url_helpers # neeeded for _path helpers to work in models
  # def admin_link # for Paper Trail
  #   nil
  # end

end
