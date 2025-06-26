class Task < ApplicationRecord
  # Associations

  belongs_to :project
  belongs_to :user
  has_many :task_tags, dependent: :destroy
  has_many :tags, through: :task_tags

  # Validations

  validates :title, presence: true
  validates :status, presence: true
  validates :due_date, presence: true
end
