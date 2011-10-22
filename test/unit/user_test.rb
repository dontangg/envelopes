require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "should not save user without email and password" do
    u = User.new(email: 'email')
    assert !u.save, "Saved the user without a password"
    
    u = User.new(password: 'pass')
    assert !u.save, "Saved the user without an email"
  end
end
