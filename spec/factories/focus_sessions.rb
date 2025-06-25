FactoryBot.define do
  factory :focus_session do
    user { nil }
    task { nil }
    started_at { "2025-06-25 23:01:39" }
    ended_at { "2025-06-25 23:01:39" }
    duration_minutes { 1 }
    notes { "MyText" }
  end
end
