require 'test_helper'

class RulesControllerTest < ActionController::TestCase
  setup do
    login_as :jim
  end

  test "should require a user to be logged in" do
    logout

    get :index
    assert_redirected_to controller: 'sessions', action: 'new'
  end
  
  test "should get index" do
    get :index
    assert_response :success
    
    assert_not_nil assigns(:new_rule)
    assert_not_nil assigns(:rules)
    assert_not_nil assigns(:all_envelopes)
  end

  test "should create a new rule" do
    assert_difference "Rule.count", 1 do
      post :create, {
        format: :js,
        rule: {
          search_text: 'test search',
          replacement_text: 'test replace',
          user_id: users(:jim).id,
          envelope_id: envelopes(:groceries)
        }
      }
    end
    
    assert_not_nil assigns(:rule)
    assert_not_nil assigns(:all_envelopes)
  end

  test "should update a rule" do
    put :update, {
      id: rules(:walmart).id,
      rule: { search_text: 'newtext' }
    }
    
    assert_response :success
  end
  
  test "should delete a rule" do
    assert_difference "Rule.count", -1 do
      delete :destroy, {
        id: rules(:walmart).id
      }
    end

    assert_response :success
  end

end
