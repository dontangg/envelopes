# Gemnasium https://gemnasium.com/dontangg/envelopes
source 'http://rubygems.org'

gem 'rails', '~> 4.1.8'
gem 'unicorn' unless RUBY_PLATFORM =~ /mingw32/i
gem 'jquery-rails'
gem 'cancan', '~> 1.6'
gem 'syrup', git: 'git://github.com/dontangg/syrup.git'
gem 'gibberish'
gem 'bcrypt-ruby', '~> 3.1.2' # To use ActiveModel has_secure_password

# To use Jbuilder templates for JSON
# gem 'jbuilder'

gem 'sass-rails',   '~> 4.0.0'
gem 'coffee-rails', '~> 4.1.0'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer', :platform => :ruby

gem 'uglifier',     '>= 1.3.0'

gem 'slim-rails'

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
  gem 'minitest'
  gem 'simplecov', require: false
end

group :development do
  gem 'rake'
  gem 'guard-minitest'
  gem 'rb-fsevent', require: false #if RUBY_PLATFORM =~ /darwin/i
  gem 'foreman'
  gem 'capistrano', '~> 2.15.4'

  # For code quality
  # rails_best_practices
end

gem 'pg', '~> 0.17.0', group: :production
