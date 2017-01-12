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

  USER_NAME_EMAIL_PAIRS = [
    ['aaron', 'aaron@brightbytes.net']
  ].freeze

  USER_NAME_EMAIL_PAIRS.each do |(name, email)|
    instance_eval %[
      def #{name}
        @#{name} ||= User.find_by(email: '#{email}')
      end
    ]
  end

  USER_NAMES = USER_NAME_EMAIL_PAIRS.map(&:first)

  def self.flush_cache
    # Ugly ... but automatic ...
    USER_NAMES.each { |name| instance_variable_set("@#{name}", nil) }
  end

end
