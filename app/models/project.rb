class Project < ApplicationRecord
  belongs_to :user
  has_many :tasks, dependent: :destroy

  validates :name, presence: true
  validates :name, uniqueness: { scope: :user_id }

  # Scopes
  scope :with_tasks, -> { joins(:tasks).distinct }
  scope :recent, -> { order(created_at: :desc) }

  # Methods
  def task_count
    tasks.count
  end

  def completed_task_count
    tasks.completed.count
  end

  def completion_percentage
    return 0 if task_count.zero?
    ((completed_task_count.to_f / task_count) * 100).round(1)
  end

  def total_estimated_time
    tasks.sum(:estimated_minutes)
  end

  def total_actual_time
    tasks.joins(:focus_sessions).sum('focus_sessions.duration_minutes')
  end
end