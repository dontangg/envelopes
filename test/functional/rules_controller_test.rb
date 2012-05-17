require 'test_helper'

class RulesControllerTest < ActionController::TestCase
  setup do
    @user = login
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
    assert_not_nil assigns(:envelope_options_for_select)
  end

  test "should create a new rule" do
    envelope = create :envelope, user: @user

    assert_difference "Rule.count", 1 do
      post :create, {
        format: :js,
        rule: {
          search_text: 'test search',
          replacement_text: 'test replace',
          user_id: @user.id,
          envelope_id: envelope.id
        }
      }
    end
    
    assert_not_nil assigns(:rule)
    assert_not_nil assigns(:envelope_options_for_select)
  end

  test "should update a rule" do
    rule = create :rule, user: @user

    put :update, {
      id: rule.id,
      rule: { search_text: 'newtext' }
    }
    
    assert_response :success

    rule.reload

    assert_equal 'newtext', rule.search_text
  end
  
  test "should delete a rule" do
    rule = create :rule, user: @user

    assert_difference "Rule.count", -1 do
      delete :destroy, {
        id: rule.id
      }
    end

    assert_response :success
  end

  test "should run all rules now" do
    envelope0 = create :unassigned_envelope, user: @user
    envelope1 = create :envelope, name: 'Groceries', user: @user
    envelope2 = create :envelope, name: 'Gas', user: @user

    transaction0 = create :transaction, envelope: envelope0, original_payee: 'WALMART1', payee: 'WALMART1'
    transaction1 = create :transaction, envelope: envelope1, original_payee: 'WALMART2', payee: 'WALMART2'
    transaction2 = create :transaction, envelope: envelope0, original_payee: 'MAVERIK', payee: 'MAVERIK'

    rule0 = create :rule, search_text: 'WALM', replacement_text: 'Walmart', envelope: nil, order: 0, user: @user
    rule1 = create :rule, search_text: 'MAVE', replacement_text: nil, envelope_id: envelope2.id, order: 1, user: @user

    post :run_all, { format: :js }

    assert_response :success
    assert_equal 2, assigns(:changed_count)

    transaction0.reload
    transaction1.reload
    transaction2.reload

    assert_equal 'Walmart', transaction0.payee
    assert_equal envelope0.id, transaction0.envelope_id
    assert_equal 'WALMART2', transaction1.payee
    assert_equal envelope1.id, transaction1.envelope_id
    assert_equal 'MAVERIK', transaction2.payee
    assert_equal envelope2.id, transaction2.envelope_id
  end

end
