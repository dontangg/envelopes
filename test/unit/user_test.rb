require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "should not save user without email and password" do
    u = User.new(email: 'email')
    assert !u.save, "Saved the user without a password"
    
    u = User.new(password: 'pass')
    assert !u.save, "Saved the user without an email"
  end

  test "should save with correct info supplied" do
    u = User.new(email: 'email', password: 'pass')

    assert u.save, "Didn't save the user even though email and password were supplied"
  end

  test "if user changes their email address, the bank password is re-encrypted" do
    u = User.new(email: 'test')
    u.build_bank
    u.bank.password = 'mypass'
    
    assert_equal 'mypass', u.bank.password

    u.email = 'newtest'

    assert_equal 'mypass', u.bank.password
  end

  test "should not allow duplicate emails to be saved" do
    u1 = User.create(email: 'email', password: 'pass')

    u2 = User.new(email: 'email', password: 'pass')

    assert !u2.save, "Allowed multiple users to be created with the same email address"
  end

  test "should not allow password_digest to be mass assigned" do
    u = User.new(email: 'email', password_digest: 'passdigest')

    assert_equal 'email', u.email
    assert u.password_digest.blank?

    u.password_digest = 'passdigest'

    assert_equal 'passdigest', u.password_digest
  end

  test "income_envelope should get the income envelope" do
    user_id = FactoryGirl.create(:income_envelope).user.id
    envelope = User.find(user_id).income_envelope

    assert envelope.income?
  end

  test "unassigned_envelope should get the unassigned envelope" do
    user_id = FactoryGirl.create(:unassigned_envelope).user.id
    envelope = User.find(user_id).unassigned_envelope

    assert envelope.unassigned?
  end

end
