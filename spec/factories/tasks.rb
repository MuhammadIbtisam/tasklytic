FactoryBot.define do
  factory :task do
    title { "MyString" }
    description { "MyText" }
    project { nil }
    user { nil }
    priority { 1 }
    estimated_minutes { 1 }
    status { 1 }
    due_date { "2025-06-25 21:57:41" }
  end
end
