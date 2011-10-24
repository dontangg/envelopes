source 'http://rubygems.org'

gem 'rails', '3.1.1'

# Gems used only for assets and not required in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.1.4'
  gem 'coffee-rails', '~> 3.1.1'
  gem 'uglifier',     '>= 1.0.3'
end

gem 'jquery-rails'

# To use ActiveModel has_secure_password
gem 'bcrypt-ruby', '~> 3.0.0'

# To use debugger
# gem 'ruby-debug19', :require => 'ruby-debug'

gem 'sqlite3', group: [:development, :test]

group :development do
  gem 'guard-test'
  gem 'rb-fsevent', require: false if RUBY_PLATFORM =~ /darwin/i
end

group :test do
  # Pretty printed test output
  gem 'turn', :require => false
end

gem 'pg', group: :production
