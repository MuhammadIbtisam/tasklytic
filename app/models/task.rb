class Task < ApplicationRecord
  # Associations

  belongs_to :project
  belongs_to :user
  has_many :task_tags, dependent: :destroy
  has_many :tags, through: :task_tags
  has_many :focus_sessions, dependent: :destroy

  # Enums
  enum status: {
    pending: 0,
    in_progress: 1,
    completed: 2,
    cancelled: 3
  }

  enum priority: {
    low: 0,
    medium: 1,
    high: 2,
    urgent: 3
  }

  # Scopes
  scope :overdue, -> { where('due_date < ? AND status != ?', Time.current, statuses[:completed]) }
  scope :due_today, -> { where(due_date: Time.current.beginning_of_day..Time.current.end_of_day) }
  scope :due_this_week, -> { where(due_date: Time.current.beginning_of_week..Time.current.end_of_week) }

  # Validations

  validates :title, presence: true
  validates :status, presence: true
  validates :due_date, presence: true
  validates :priority, presence: true

  def total_focus_time
    focus_sessions.sum(:duration_minutes)
  end

  def estimated_vs_actual_time
    return nil unless estimated_minutes && total_focus_time > 0
    ((total_focus_time.to_f / estimated_minutes) * 100).round(1)
  end
end
