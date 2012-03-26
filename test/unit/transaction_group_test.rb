require 'test_helper'

class TransactionTest < ActiveSupport::TestCase
  test "should not allow a transaction group to be created without an envelope" do
    group = FactoryGirl.build(:transaction_group, envelope: nil)
    assert !group.save

    group.envelope = FactoryGirl.build(:envelope, user: group.user)
    assert group.save
  end

  test "should not allow a transaction group to be created without a user" do
    group = FactoryGirl.build(:transaction_group,
      user: nil,
      envelope: FactoryGirl.build(:envelope, user: FactoryGirl.build(:user))
    )
    assert !group.save, group.errors.full_messages.join

    group.user = group.envelope.user
    assert group.save, group.errors.full_messages.join
  end

  test "should not allow a transaction group to be created without a year_month" do
    group = FactoryGirl.build(:transaction_group, year_month: nil)
    assert !group.save, group.errors.full_messages.join

    group.year_month = '2012-03'
    assert group.save, group.errors.full_messages.join
  end

  test "should not allow a transaction group to be created without a total_amount" do
    group = FactoryGirl.build(:transaction_group, total_amount: nil)
    assert !group.save, group.errors.full_messages.join

    group.total_amount = 1.23
    assert group.save, group.errors.full_messages.join
  end

end

