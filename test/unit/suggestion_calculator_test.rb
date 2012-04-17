require 'test_helper'

class SuggestionCalculatorTest < ActiveSupport::TestCase

  test "should give suggestions for monthly envelopes" do
    env0 = create :envelope
    env1 = create :envelope, expense: Expense.new(frequency: :monthly, amount: 50.to_d), user: env0.user, parent_envelope: env0
    env2 = create :envelope, expense: Expense.new(frequency: :monthly, amount: 40.55.to_d), user: env0.user, parent_envelope: env0
    create :transaction, :transfer, envelope: env2, amount: 20.to_d

    organized_envelopes = Envelope.organize([env0, env1, env2])
    SuggestionCalculator.calculate(organized_envelopes)

    assert_in_delta 50.0, env1.suggested_amount, 0.001
    assert_in_delta 20.55, env2.suggested_amount, 0.001
    assert_in_delta 70.55, env0.suggested_amount, 0.001
  end

  test "should suggest 0.00 for envelopes without an expense" do
    env1 = create :envelope, expense: nil

    organized_envelopes = Envelope.organize([env1])
    SuggestionCalculator.calculate(organized_envelopes)

    assert_equal 0.0, env1.suggested_amount
  end

  test "should give suggestions for yearly envelopes" do
    env0 = create :envelope
    env1 = create :envelope, expense: Expense.new(frequency: :yearly, amount: 50.to_d, occurs_on_month: (Date.today - 2.months).month), user: env0.user, parent_envelope: env0
    env2 = create :envelope, expense: Expense.new(frequency: :yearly, amount: 40.44.to_d, occurs_on_month: (Date.today + 1.months).month), user: env0.user, parent_envelope: env0
    env3 = create :envelope, expense: Expense.new(frequency: :yearly, amount: 24.to_d), user: env0.user, parent_envelope: env0
    create :transaction, :transfer, posted_at: Date.today, envelope: env2, amount: 20.to_d

    organized_envelopes = Envelope.organize([env0, env1, env2, env3])
    SuggestionCalculator.calculate(organized_envelopes)

    assert_in_delta 0.0, env1.suggested_amount, 0.001
    assert_in_delta 0.22, env2.suggested_amount, 0.001
    assert_in_delta 2.0, env3.suggested_amount, 0.001
    assert_in_delta 2.22, env0.suggested_amount, 0.001
  end

  test "once funded, yearly suggestions are all 0" do
    env0 = create :envelope
    env1 = create :envelope, expense: Expense.new(frequency: :yearly, amount: 50.to_d, occurs_on_month: (Date.today - 2.months).month), user: env0.user, parent_envelope: env0
    env2 = create :envelope, expense: Expense.new(frequency: :yearly, amount: 40.44.to_d, occurs_on_month: (Date.today + 1.months).month), user: env0.user, parent_envelope: env0
    env3 = create :envelope, expense: Expense.new(frequency: :yearly, amount: 23.22.to_d, occurs_on_month: (Date.today + 2.months).month), user: env0.user, parent_envelope: env0
    create :transaction, :transfer, posted_at: Date.today, envelope: env2, amount: 21.22.to_d

    organized_envelopes = Envelope.organize([env0, env1, env2, env3])
    SuggestionCalculator.calculate(organized_envelopes)

    assert_in_delta 0.0, env1.suggested_amount, 0.001
    assert_in_delta 0.0, env2.suggested_amount, 0.001
    assert_in_delta 0.0, env3.suggested_amount, 0.001
    assert_in_delta 0.0, env0.suggested_amount, 0.001
  end

end
