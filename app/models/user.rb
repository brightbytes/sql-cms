# == Schema Information
#
# Table name: public.users
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

  # Associations

  has_many :notifications, inverse_of: :user
  has_many :observed_workflow_configurations, through: :notifications, source: :workflow_configuration

  has_many :runs, foreign_key: :creator_id, inverse_of: :creator

  # Instance Methods

  def full_name
    "#{first_name} #{last_name}".squish
  end

  def rfc_email_address
    "#{full_name} <#{email}>".squish
  end

  alias_method :to_s, :rfc_email_address

  # Class Methods

  # Can't use the memoize gem here, because the gem gags on both explicit flushing (e.g. User.admin(true)) and implicit flushing (i.e. User.flush_cache).  Lame.

  UserSeeder::USERS.each do |hash|
    name = hash[:first_name].downcase
    email = hash[:email]
    instance_eval %[
      def #{name}
        @#{name} ||= User.find_by(email: '#{email}')
      end
    ]
  end

  # If ever we end up with 2 folks with the same name, this will fail.  Bah.
  USER_NAMES = UserSeeder::USERS.map { |hash| hash[:first_name].downcase }

  class << self

    def flush_cache
      # Ugly ... but automatic ...
      USER_NAMES.each { |name| instance_variable_set("@#{name}", nil) }
    end

  end
end
