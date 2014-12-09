require 'simplecov'
SimpleCov.start 'rails'

ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

Rails.logger.level = 4

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
