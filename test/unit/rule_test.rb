require 'test_helper'

class RuleTest < ActiveSupport::TestCase
  test "search text and user id are required" do
    user = create :user

    rule = Rule.new
    assert !rule.save
    
    rule.user_id = user.id
    assert !rule.save
    rule.user_id = nil
    
    rule.search_text = 'test'
    assert !rule.save
    
    rule.user_id = user.id
    assert rule.save
  end

  test "rules are returned ordered by `order`" do
    rule1 = create :rule, search_text: 'rule1', order: 1
    rule0 = create :rule, search_text: 'rule0', order: 0, user: rule1.user
    rule2 = create :rule, search_text: 'rule2', order: 2, user: rule1.user

    in_right_order = true
    prev_order = -1
    Rule.unscoped.each do |rule|
      in_right_order = false if prev_order > rule.order
      prev_order = rule.order
    end
    assert !in_right_order, "Can't do a proper test of ordering if they're already in order"

    prev_order = -1
    Rule.all.each do |rule|
      assert rule.order >= prev_order, "Rules were returned in the wrong order (#{rule.order} <= #{prev_order})"
      prev_order = rule.order
    end
  end

  test "running a rule that doesn't find the search_text should return nil" do
    rule = build :rule, search_text: 'test payee'
    assert_nil rule.run('a different payee')
  end

  test "running a rule that contains the search_text should return correct envelope_id and payee" do
    rule = build :rule, search_text: 'test payee', replacement_text: 'replacement', envelope_id: 5

    run_result = rule.run('There is a test payee in here')
    assert_equal 'replacement', run_result[0]
    assert_equal 5, run_result[1]

    rule.replacement_text = nil
    rule.envelope_id = nil
    run_result = rule.run('There is a test payee in here')
    assert_equal 'There is a test payee in here', run_result[0]
    assert_nil run_result[1]
  end

  test "owned_by should only return rules for the specified user" do
    rule1 = create :rule
    rule2 = create :rule, user: create(:user, email: 'junk not used')

    assert Rule.owned_by(rule1.user.id).all? { |rule| rule1.user.id == rule.user.id }
  end
end
