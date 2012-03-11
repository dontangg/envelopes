require 'test_helper'

class EnvelopesHelperTest < ActionView::TestCase
  test "should make a nice string for monthly expenses with a day" do
    expense = Expense.new amount: 3.4, frequency: :monthly, occurs_on_day: 1

    str = stringify_expense_frequency(expense)

    assert_equal "on the 1st day of every month", str
  end

  test "should make a nice string for monthly expenses without a day" do
    expense = Expense.new amount: 3.4, frequency: :monthly

    str = stringify_expense_frequency(expense)

    assert_equal "every month", str
  end

  test "monthly expenses scheduled for the 31 should say 'last'" do
    expense = Expense.new amount: 5.22, frequency: :monthly, occurs_on_day: 31

    str = stringify_expense_frequency(expense)

    assert_equal "on the last day of every month", str
  end

  test "should make a nice string for yearly expenses with a day and month" do
    expense = Expense.new amount: 8.09, frequency: :yearly, occurs_on_day: 1, occurs_on_month: 1

    str = stringify_expense_frequency(expense)

    assert_equal "on January 1st every year", str

  end

  test "should make a nice string for yearly expenses without a day or month" do
    expense = Expense.new amount: 8.09, frequency: :yearly

    str = stringify_expense_frequency(expense)

    assert_equal "every year", str
  end

  test "content for frequency popover returns the right kind of string" do
    envelope = Envelope.new
    envelope.expense = Expense.new amount: 8.09, frequency: :yearly
    
    str = content_for_frequency_popover(envelope)

    assert !str.html_safe?
  end
end
