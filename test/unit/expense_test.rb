require 'test_helper'

class EnvelopeTest < ActiveSupport::TestCase
  test "initialize can accept all properties and set them" do
    expense = Expense.new amount: 5.2, frequency: :monthly, occurs_on: { day: 1, month: 1 }

    assert_equal 5.2, expense.amount
    assert_equal :monthly, expense.frequency
    assert_equal 1, expense.occurs_on[:day]
    assert_equal 1, expense.occurs_on[:month]
  end

  test "uninitialized properties return a valid value" do
    expense = Expense.new

    assert_kind_of Float, expense.amount
    assert_equal :monthly, expense.frequency
    assert_kind_of Hash, expense.occurs_on
  end
end

