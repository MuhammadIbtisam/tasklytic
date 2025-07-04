FactoryBot.define do
  factory :project do
    sequence(:name) { |n| "Project #{n}" }
    description { "A test project description" }
    association :user

    trait :with_many_tasks do
      after(:create) do |project|
        create_list(:task, 10, project: project)
      end
    end

    trait :completed do
      after(:create) do |project|
        create_list(:task, 5, project: project, status: :completed)
      end
    end

    trait :with_mixed_tasks do
      after(:create) do |project|
        create_list(:task, 3, project: project, status: :completed)
        create_list(:task, 2, project: project, status: :pending)
        create_list(:task, 1, project: project, status: :in_progress)
      end
    end

    trait :with_overdue_tasks do
      after(:create) do |project|
        create_list(:task, 3, project: project, due_date: 1.day.ago, status: :pending)
      end
    end

    trait :with_focus_sessions do
      after(:create) do |project|
        task = create(:task, project: project)
        create_list(:focus_session, 3, task: task, duration_minutes: 30)
      end
    end
  end
end
