FactoryBot.define do
  factory :task do
    sequence(:title) { |n| "Task #{n}" }
    description { "A test task description" }
    association :project
    association :user
    priority { :medium }
    estimated_minutes { 60 }
    status { :pending }
    due_date { 1.week.from_now }
  end
end
