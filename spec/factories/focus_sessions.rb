FactoryBot.define do
  factory :focus_session do
    association :user
    association :task
    started_at { 1.hour.ago }
    ended_at { 30.minutes.ago }
    duration_minutes { 30 }
    notes { "Test focus session notes" }
  end
end
