require 'test_helper'

class SuggestionCalculatorTest < ActiveSupport::TestCase

  test "should give suggestions for monthly envelopes" do
    env0 = create :envelope
    env1 = create :envelope, expense: Expense.new(frequency: :monthly, amount: 50), user: env0.user, parent_envelope: env0
    env2 = create :envelope, expense: Expense.new(frequency: :monthly, amount: 40.55), user: env0.user, parent_envelope: env0
    create :transaction, :transfer, envelope: env2, amount: 20

    organized_envelopes = Envelope.organize([env0, env1, env2])
    SuggestionCalculator.calculate(organized_envelopes)

    assert_equal 90.55, env0.suggested_amount
    assert_equal 50.0, env1.suggested_amount
    assert_equal 40.55, env2.suggested_amount
  end

  test "should suggest 0.00 for envelopes without an expense" do
    env1 = create :envelope, expense: nil

    organized_envelopes = Envelope.organize([env1])
    SuggestionCalculator.calculate(organized_envelopes)

    assert_equal 0.0, env1.suggested_amount
  end

  test "should give suggestions for yearly envelopes" do
    env0 = create :envelope
    env1 = create :envelope, expense: Expense.new(frequency: :yearly, amount: 50, occurs_on_month: (Date.today - 2.months).month), user: env0.user, parent_envelope: env0
    env2 = create :envelope, expense: Expense.new(frequency: :yearly, amount: 40.44, occurs_on_month: (Date.today + 1.months).month), user: env0.user, parent_envelope: env0
    env3 = create :envelope, expense: Expense.new(frequency: :yearly, amount: 24), user: env0.user, parent_envelope: env0
    create :transaction, :transfer, envelope: env2, amount: 20

    organized_envelopes = Envelope.organize([env0, env1, env2, env3])
    SuggestionCalculator.calculate(organized_envelopes)

    assert_equal 22.22, env0.suggested_amount
    assert_equal 0.0, env1.suggested_amount
    assert_equal 20.22, env2.suggested_amount
    assert_equal 2.0, env3.suggested_amount

  end

end
