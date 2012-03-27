ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
#require 'turn'


class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  #
  # fixtures :all

  def login_as(user)
    session[:user_id] = users(user).id
  end

  def logout
    session.delete :user_id
  end
end

class ActiveSupport::TestCase
  # Drop all collections after each test case.
  def teardown
    # TODO: Find out why data is still erased when the test fails
    Mongoid.master.collections.select {|c| c.name !~ /system/ }.each(&:drop) if self.passed?
  end

  # Make sure that each test case has a teardown method to clear the db after each test.
  def inherited(base)
    base.define_method teardown do 
      super
    end
  end
end
