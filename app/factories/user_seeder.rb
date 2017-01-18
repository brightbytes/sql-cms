module UserSeeder

  extend self

  def seed
    env_password = ENV['UI_ADMIN_PASSWORD'] || 'password'
    USERS.each do |h|
      h[:password] = h[:password_confirmation] = env_password
      # NOTE - WE CAN'T USE find_or_create_by! HERE B/C DEVISE WILL PUKE ON IT; SEE:
      #        http://stackoverflow.com/questions/25497473/rails-4-1-devise-3-3-column-users-password-does-not-exist
      User.create!(h) unless User.where(email: h[:email]).exists?
    end
  end

  USERS = [
    {
      email: 'aaron@brightbytes.net',
      first_name: 'Aaron',
      last_name: 'Cohen'
    }
  ]

end
