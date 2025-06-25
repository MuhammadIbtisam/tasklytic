class Task < ApplicationRecord
  belongs_to :project
  belongs_to :user
  has_many :task_tags, dependent: :destroy
  has_many :tags, through: :task_tags
end
