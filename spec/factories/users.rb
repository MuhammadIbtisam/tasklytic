FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    avatar { nil }
    total_focus_time { rand(0..1000) }
    sign_in_count { rand(0..50) }
    current_sign_in_at { Time.current }
    last_sign_in_at { 1.hour.ago }
    current_sign_in_ip { Faker::Internet.ip_v4_address }
    last_sign_in_ip { Faker::Internet.ip_v4_address }

    trait :unconfirmed do
      # No confirmable columns in database, so this trait is not applicable
    end

    trait :with_reset_password do
      reset_password_token { SecureRandom.hex(10) }
      reset_password_sent_at { Time.current }
    end

    trait :with_avatar do
      avatar { "https://example.com/avatar.jpg" }
    end

    trait :with_focus_time do
      total_focus_time { rand(1000..10000) }
    end

    trait :productive do
      total_focus_time { rand(5000..20000) }
    end

    trait :new_user do
      total_focus_time { 0 }
      sign_in_count { 1 }
    end

    trait :locked do
      # No lockable columns in database, so this trait is not applicable
    end

    # trait :admin do
    #   # role { 'admin' }
    # end
  end
end