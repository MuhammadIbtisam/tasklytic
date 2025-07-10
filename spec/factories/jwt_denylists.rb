FactoryBot.define do
  factory :jwt_denylist do
    jti { "MyString" }
    exp { "2025-07-07 23:55:01" }
  end
end
