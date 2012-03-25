require 'test_helper'

class RuleTest < ActiveSupport::TestCase
  test "search text is required" do
    user = FactoryGirl.create(:user)

    rule = user.rules.build
    assert !user.save
    
    rule.search_text = 'test search text'
    assert user.save
  end

  test "running a rule returns the correct replacement and envelope id" do
    rule = FactoryGirl.create(:rule)

    result = rule.run("12398465 P.O.S. WALMART 142")

    assert_equal "Walmart", result[0]
    assert_equal 123, result[1]
  end

  test "rules should be read in the right order" do
    user = FactoryGirl.create(:user)

    FactoryGirl.create(:rule, user: user, order: 2)
    FactoryGirl.create(:rule, user: user, order: 1)
    FactoryGirl.create(:rule, user: user, order: 4)
    FactoryGirl.create(:rule, user: user, order: 3)

    # Read the user to get the order right
    user = User.find(user.id)

    prev_order = 0
    user.rules.each do |rule|
      assert prev_order < rule.order, "Rules should be ordered (#{prev_order} < #{rule.order})"
      prev_order = rule.order
    end
  end
end
