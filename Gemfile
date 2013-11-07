# Gemnasium https://gemnasium.com/dontangg/envelopes
source 'http://rubygems.org'

gem 'rails', '~> 3.2.3'
gem 'unicorn' unless RUBY_PLATFORM =~ /mingw32/i
gem 'jquery-rails'
gem 'cancan', '~> 1.6'
gem 'syrup', git: 'git://github.com/dontangg/syrup.git'
gem 'gibberish'
gem 'bcrypt-ruby', '~> 3.0.0' # To use ActiveModel has_secure_password

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Gems used only for assets and not required in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer', :platform => :ruby

  gem 'uglifier',     '>= 1.2'
end

# Put test-only gems in this group so their generators
# and rake tasks are available in development mode:
group :development, :test do
  gem 'sqlite3'
  gem 'factory_girl_rails'

  # The debugger gem isn't very compatible with Ruby 2.0, so we'll use byebug
  #gem 'debugger'
  gem 'byebug'
end

group :test do
  gem 'turn'
  gem 'minitest'
  gem 'simplecov', require: false
end

group :development do
  gem 'rake'
  gem 'guard-minitest'
  gem 'rb-fsevent', require: false #if RUBY_PLATFORM =~ /darwin/i
  gem 'foreman'
  gem 'capistrano'

  # For code quality
  # rails_best_practices
end

gem 'pg', '~> 0.17.0', group: :production
