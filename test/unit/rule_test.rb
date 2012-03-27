require 'test_helper'

class RuleTest < ActiveSupport::TestCase
  test "search text and user id are required" do
    rule = Rule.new
    assert !rule.save
    
    rule.user_id = users(:jim).id
    assert !rule.save
    rule.user_id = nil
    
    rule.search_text = 'test'
    assert !rule.save
    
    rule.user_id = users(:jim).id
    assert rule.save
  end
end
