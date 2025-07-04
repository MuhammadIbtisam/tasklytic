source "https://rubygems.org"

ruby "3.1.6"

gem "rails", "~> 7.1.3"
gem "pg", "~> 1.5"
gem "puma", "~> 6.4"
gem "redis", "~> 5.0"

gem 'devise', '~> 4.9'
gem 'devise-jwt', '~> 0.11.0'
gem 'sidekiq', '~> 7.2'
gem 'rswag-api', '~> 2.13'
gem 'rswag-ui', '~> 2.13'
gem 'active_model_serializers', '~> 0.10.14'
gem 'ruby-openai', '~> 6.3'
gem 'kaminari', '~> 1.2'
gem 'rack-cors', '~> 2.0'
gem "tzinfo-data", platforms: %i[ windows jruby ]
gem "bootsnap", require: false

group :development, :test do
  gem "debug", platforms: %i[ mri windows ]
  gem 'rspec-rails', '~> 6.1'
  gem 'factory_bot_rails', '~> 6.4'
  gem 'faker', '~> 3.2'
  gem 'database_cleaner-active_record', '~> 2.1'
  gem 'rswag-specs', '~> 2.13'
  gem 'dotenv-rails', '~> 3.1'
end

group :test do
  gem 'shoulda-matchers'
end

group :development do
  # gem "spring"
end

