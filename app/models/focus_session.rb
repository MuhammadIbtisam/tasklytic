class FocusSession < ApplicationRecord
  belongs_to :user
  belongs_to :task

  validate :ended_at_after_started_at

  private

  def ended_at_after_started_at
    return unless started_at && ended_at
    if started_at > ended_at
      errors.add(:ended_at, "ended_at must be after started at...")
    end
  end
end
