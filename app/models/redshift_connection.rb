class RedshiftConnection < ActiveRecord::Base

  self.abstract_class = true

  establish_connection(:redshift) if ENV['REDSHIFT_HOST'].present?

end
