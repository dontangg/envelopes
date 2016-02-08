# Gemnasium https://gemnasium.com/dontangg/envelopes
source 'http://rubygems.org'

gem 'rails', '~> 4.2.5.1'
gem 'unicorn' unless RUBY_PLATFORM =~ /mingw32/i
gem 'jquery-rails'
gem 'cancan', '~> 1.6'
gem 'syrup', git: 'git://github.com/dontangg/syrup.git'
gem 'nokogiri', '1.6.5' # Locking version because of trouble updating
gem 'gibberish'
#gem 'bcrypt-ruby', '~> 3.1.2' # To use ActiveModel has_secure_password
gem 'bcrypt', '~> 3.1.7' # To use ActiveModel has_secure_password

# To use Jbuilder templates for JSON
# gem 'jbuilder', '~>2.0'

gem 'sass-rails',   '~> 5.0'
gem 'coffee-rails', '~> 4.1.0'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer', :platform => :ruby

gem 'uglifier',     '>= 1.3.0'

# Put test-only gems in this group so their generators
# and rake tasks are available in development mode:
group :development, :test do
  gem 'sqlite3'
  gem 'factory_girl_rails'

  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
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
  #gem 'capistrano', '~> 2.15.4'
  gem 'capistrano-rails'

  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'

  # For code quality
  # rails_best_practices
end

gem 'pg', '~> 0.17.0', group: :production
