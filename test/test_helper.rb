require 'simplecov'
SimpleCov.start 'rails'

ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

Rails.logger.level = 4

Turn.config do |c|
 # use one of output formats:
 # :outline  - turn's original case/test outline mode [default]
 # :progress - indicates progress with progress bar
 # :dotted   - test/unit's traditional dot-progress mode
 # :pretty   - new pretty reporter
 # :marshal  - dump output as YAML (normal run mode only)
 # :cue      - interactive testing
 c.format  = :outline
 # number of backtrace lines to display (nil == all)
 c.trace   = nil
 # use humanized test names (works only with :outline format)
 c.natural = true
end

class ActiveSupport::TestCase
  # expose create and build methods
  include FactoryGirl::Syntax::Methods

  def login
    login_as(create(:user))
  end

  def login_as(user)
    session[:user_id] = user.id
    user
  end
  
  def logout
    session.delete :user_id
  end
end
