require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "should not save user without email and password" do
    u = User.new(email: 'email')
    assert !u.save, "Saved the user without a password"
    
    u = User.new(password: 'pass')
    assert !u.save, "Saved the user without an email"
  end

  test "if user changes their email address, the bank password is re-encrypted" do
    u = User.new(email: 'test', bank_password: 'mypass')
    
    assert_equal 'mypass', u.bank_password

    u.email = 'newtest'

    assert_equal 'mypass', u.bank_password
  end
end
