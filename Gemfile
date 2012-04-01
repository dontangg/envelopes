# Gemnasium https://gemnasium.com/dontangg/envelopes
source 'http://rubygems.org'

gem 'rails', '3.2.3'
gem 'unicorn' unless RUBY_PLATFORM =~ /mingw32/i
gem 'jquery-rails'
gem 'cancan', '~> 1.6'
gem 'syrup', '~> 0.0.11'
gem 'gibberish'
gem 'bcrypt-ruby', '~> 3.0.0' # To use ActiveModel has_secure_password
# gem 'ruby-debug19', :require => 'ruby-debug' # To use debugger

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

group :development, :test do
  gem 'sqlite3'
  gem 'factory_girl_rails'
  gem 'turn'
  gem 'minitest'
end

group :development do
  gem 'rake'
  gem 'guard-minitest'
  gem 'rb-fsevent', require: false #if RUBY_PLATFORM =~ /darwin/i
  gem 'foreman'
  gem 'capistrano'
end

gem 'pg', group: :production
