class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :lockable, :timeoutable, :trackable

  # Associations
  has_many :projects
  has_many :tasks
  has_many :focus_sessions

  # Validations
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true, uniqueness: true

  #methods
  def full_name
    "#{first_name} #{last_name}"
  end

  def total_focus_hours
    total_focus_time.to_f / 60
  end
end