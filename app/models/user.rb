class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :timeoutable, :trackable, :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

  # Associations
  has_many :projects
  has_many :tasks
  has_many :focus_sessions

  # Validations
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true, uniqueness: true

  #methods
  before_create :set_jti

  def full_name
    "#{first_name} #{last_name}"
  end

  def total_focus_hours
    total_focus_time.to_f / 60
  end

  def generate_jwt
    JWT.encode({ id: id, email: email, jti: jti }, Rails.application.credentials.secret_key_base, 'HS256')
  end

  private

  def set_jti
    self.jti ||= SecureRandom.uuid
  end
end