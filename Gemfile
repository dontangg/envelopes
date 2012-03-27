source 'http://rubygems.org'

gem 'rails', '3.2.2'
gem 'unicorn' unless RUBY_PLATFORM =~ /mingw32/i
gem 'jquery-rails'
gem 'cancan', '~> 1.6'
gem 'syrup', '~> 0.0.9'
gem 'gibberish'
gem 'bcrypt-ruby', '~> 3.0.0' # To use ActiveModel has_secure_password
# gem 'ruby-debug19', :require => 'ruby-debug' # To use debugger

# Gems used only for assets and not required in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier',     '>= 1.0.3'
end

gem 'sqlite3', group: [:development, :test]

group :development do
  gem 'guard-test'
  gem 'rb-fsevent', require: false #if RUBY_PLATFORM =~ /darwin/i
  gem 'foreman'
end

gem 'pg', group: :production
