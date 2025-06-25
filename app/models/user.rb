class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :timeoutable, :trackable

  # Validations
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true, uniqueness: true

  # Instance methods
  def full_name
    "#{first_name} #{last_name}"
  end

  def total_focus_hours
    total_focus_time.to_f / 60
  end

  def active?
    last_active_at && last_active_at > 1.hour.ago
  end
end
