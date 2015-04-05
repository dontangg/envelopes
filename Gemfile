# Gemnasium https://gemnasium.com/dontangg/envelopes
source 'http://rubygems.org'

gem 'rails', '~> 4.2.1'
gem 'unicorn' unless RUBY_PLATFORM =~ /mingw32/i
gem 'jquery-rails'
gem 'cancan', '~> 1.6'
gem 'syrup', git: 'git://github.com/dontangg/syrup.git'
gem 'gibberish'
gem 'bcrypt-ruby', '~> 3.1.2' # To use ActiveModel has_secure_password

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
#gem 'jbuilder', '~> 2.0'

gem 'sass-rails',   '~> 5.0.3'
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
  gem 'web-console', '~> 2.0'

  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  #gem 'spring'
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
