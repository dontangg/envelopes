require 'test_helper'

class ExpenseTest < ActiveSupport::TestCase
  test "initialize can accept all properties and set them" do
    expense = Expense.new amount: 5.2, frequency: :monthly, occurs_on_day: 1, occurs_on_month: 2

    assert_equal 5.2, expense.amount
    assert_equal :monthly, expense.frequency
    assert_equal 1, expense.occurs_on_day
    assert_equal 2, expense.occurs_on_month
  end

  test "uninitialized properties return a valid value" do
    expense = Expense.new

    assert_kind_of Float, expense.amount
    assert_equal 0, expense.amount
    assert_equal :monthly, expense.frequency
    assert_nil expense.occurs_on_day
    assert_nil expense.occurs_on_month
  end

  test "should return nil if day or month is set to 0" do
    expense = Expense.new occurs_on_day: 0, occurs_on_month: 0

    assert_nil expense.occurs_on_day
    assert_nil expense.occurs_on_month

    expense.occurs_on_day = 0
    assert_nil expense.occurs_on_day

    expense.occurs_on_month = 0
    assert_nil expense.occurs_on_month
  end
end

