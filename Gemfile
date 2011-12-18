source 'http://rubygems.org'

gem 'rails', '3.1.3'
gem 'unicorn'
gem 'jquery-rails'
gem 'cancan', '~> 1.6'
gem 'bcrypt-ruby', '~> 3.0.0' # To use ActiveModel has_secure_password
# gem 'ruby-debug19', :require => 'ruby-debug' # To use debugger

# Gems used only for assets and not required in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.1.4'
  gem 'coffee-rails', '~> 3.1.1'
  gem 'uglifier',     '>= 1.0.3'
end

gem 'sqlite3', group: [:development, :test]

group :development do
  gem 'guard-test'
  gem 'rb-fsevent', require: false #if RUBY_PLATFORM =~ /darwin/i
  gem 'foreman'
end

group :test do
  # Pretty printed test output
  #gem 'turn', :require => false, :git => "git://github.com/TwP/turn.git"
end

gem 'pg', group: :production
