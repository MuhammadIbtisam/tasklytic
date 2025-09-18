source "https://rubygems.org"

ruby "3.3.6"

gem "rails", "~> 8.0.2"
gem "pg", "~> 1.6"
gem "puma", "~> 6.5"
gem "redis", "~> 5.2"

gem 'devise', '~> 4.9.3'
gem 'devise-jwt', '~> 0.12.1'
gem 'sidekiq', '~> 7.3'
gem 'rswag-api', '~> 2.16'
gem 'rswag-ui', '~> 2.16'
gem 'active_model_serializers', '~> 0.10.15'
gem 'ruby-openai', '~> 8.3'
gem 'kaminari', '~> 1.2'
gem 'rack-cors', '~> 3.0'
gem "tzinfo-data", platforms: %i[ windows jruby ]
gem "bootsnap", require: false

group :development, :test do
  gem "debug", platforms: %i[ mri windows ]
  gem 'rspec-rails', '~> 7.1'
  gem 'factory_bot_rails', '~> 6.5'
  gem 'faker', '~> 3.3'
  gem 'database_cleaner-active_record', '~> 2.2'
  gem 'rswag-specs', '~> 2.16'
  gem 'dotenv-rails', '~> 3.1'
end

group :test do
  gem 'shoulda-matchers'
end

group :development do
  # gem "spring"
end

