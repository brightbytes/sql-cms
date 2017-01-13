# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  first_name             :string           not null
#  last_name              :string           not null
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :inet
#  last_sign_in_ip        :inet
#  deleted_at             :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#

class User < ApplicationRecord

  acts_as_paranoid

  auto_normalize

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :recoverable, :rememberable, :trackable, :validatable

  # Validations

  validates :first_name, :last_name, presence: true

  # Devise's email validator allows email addresses with semicolons in them, so we use our own validator in addition to their crappy one
  validates :email, email: true, presence: true, uniqueness: { case_sensitive: false }

  # Scopes

  scope :sans_deleted, -> { where(deleted_at: nil) }

  # Instance Methods

  def full_name
    "#{first_name} #{last_name}".squish
  end

  # Class Methods

  # Can't use the memoize gem here, because the gem gags on both explicit flushing (e.g. User.admin(true)) and implicit flushing (i.e. User.flush_cache).  Lame.

  USERS = [
    {
      email: 'aaron@brightbytes.net',
      first_name: 'Aaron',
      last_name: 'Cohen'
    }
  ]

  USERS.each do |hash|
    name = hash[:first_name].downcase
    email = hash[:email]
    instance_eval %[
      def #{name}
        @#{name} ||= User.find_by(email: '#{email}')
      end
    ]
  end

  USER_NAMES = USERS.map { |hash| hash[:first_name].downcase }

  class << self

    def flush_cache
      # Ugly ... but automatic ...
      USER_NAMES.each { |name| instance_variable_set("@#{name}", nil) }
    end

    def seed
      env_password = ENV['UI_ADMIN_PASSWORD'] || 'password'
      USERS.each do |h|
        h[:password] = h[:password_confirmation] = env_password
        # NOTE - WE CAN'T USE find_or_create_by! HERE B/C DEVISE WILL PUKE ON IT; SEE:
        #        http://stackoverflow.com/questions/25497473/rails-4-1-devise-3-3-column-users-password-does-not-exist
        User.create!(h) unless User.where(email: h[:email]).exists?
      end
    end

  end
end
