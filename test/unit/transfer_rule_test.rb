require 'test_helper'

class TransferRuleTest < ActiveSupport::TestCase
  test "search terms, percentage, and user id are required" do
    user = create :user

    # Without search terms
    rule = TransferRule.new
    rule.percentage = 10
    rule.user_id = user.id
    assert !rule.save
    
    # Without percentage
    rule = TransferRule.new
    rule.search_terms = 'test'
    rule.user_id = user.id
    assert !rule.save
    
    # Without user id
    rule = TransferRule.new
    rule.percentage = 10
    rule.search_terms = 'test'
    assert !rule.save
    
    # With all 3
    rule = TransferRule.new
    rule.percentage = 10
    rule.search_terms = 'test'
    rule.user_id = user.id
    assert rule.save
  end

  test "the rule matches when the search terms are included in the payee" do
    rule = build :transfer_rule, search_terms: 'apple, gOOgle'
    assert rule.match?('Google payee')
  end

  test "the rule does not match when the search terms are not included in the payee" do
    rule = build :transfer_rule, search_terms: 'apple, google'
    refute rule.match?('Walmart')
  end

  test "owned_by should only return transfer rules for the specified user" do
    rule1 = create :transfer_rule
    rule2 = create :transfer_rule, user: create(:user, email: 'junk not used')

    assert TransferRule.owned_by(rule1.user.id).all? { |rule| rule1.user.id == rule.user.id }
  end

  test "run_all returns an empty enumerable when no rules applied" do
    txn1 = build :transaction
    txn2 = build :transaction

    rule1 = build :transfer_rule

    transfer_details = TransferRule.run_all([rule1], [txn1, txn2])

    refute_nil transfer_details
    assert_equal 0, transfer_details.count
  end

  test "run_all doesn't run on negative-amount transactions" do
    txn1 = build :transaction, payee: "Google", amount: -20
    rule1 = build :transfer_rule, search_terms: "Google"

    transfer_details = TransferRule.run_all([rule1], [txn1])

    refute_nil transfer_details
    assert_equal 0, transfer_details.count
  end

  test "run_all returns one transfer per rule that applies" do
    txn1 = build :transaction, payee: "Google", amount: 20
    txn2 = build :transaction, payee: "Google", amount: 31
    txn3 = build :transaction, payee: "Apple", amount: 43
    txn4 = build :transaction, payee: "Disney", amount: 54

    rule1 = build :transfer_rule, search_terms: "Google", percentage: 10, payee: "Pay tithing"
    rule2 = build :transfer_rule, search_terms: "Apple", percentage: 28, payee: "Pay taxes"

    transfer_details = TransferRule.run_all([rule1, rule2], [txn1, txn2, txn3, txn4])

    assert_equal 2, transfer_details.count

    tithing_transfer = transfer_details.find { |t| t[:payee] == "Pay tithing" }
    assert tithing_transfer
    assert_in_delta 5.1, tithing_transfer[:amount], 0.001 # It's ok to be off by less than 1/10 of a penny

    taxes_transfer = transfer_details.find { |t| t[:payee] == "Pay taxes" }
    assert taxes_transfer
    assert_in_delta 12.04, taxes_transfer[:amount], 0.001 # It's ok to be off by less than 1/10 of a penny
  end
end
