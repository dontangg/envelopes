require 'test_helper'

class EnvelopesHelperTest < ActionView::TestCase
  test "should make a nice string for monthly expenses" do
    expense = Expense.new amount: 3.4, frequency: :monthly, occurs_on: { day: 1 }

    str = stringify_expense(expense)

    assert_equal "$3.40 on the 1st day of every month", str
  end

  test "monthly expenses scheduled for the 31 should say 'last'" do
    expense = Expense.new amount: 5.22, frequency: :monthly, occurs_on: { day: 31 }

    str = stringify_expense(expense)

    assert_equal "$5.22 on the last day of every month", str
  end

  test "should make a nice string for yearly expenses" do
    expense = Expense.new amount: 8.09, frequency: :yearly, occurs_on: { day: 1, month: 1 }

    str = stringify_expense(expense)

    assert_equal "$8.09 on January 1st every year", str

  end
end
