require 'test_helper'

class TransactionsControllerTest < ActionController::TestCase
  setup do
    @user = login
  end

  test "successful transfer" do
    from_envelope = create :envelope, user: @user
    to_envelope = create :envelope, user: @user

    assert_difference('Transaction.count', 2) do
      post :create_transfer, {
        format: :js,
        transfer_amount: '$10.00',
        transfer_from_id: from_envelope.id,
        transfer_to_id: to_envelope.id,
        current_envelope_id: from_envelope.id
      }
    end

    assert_response :success
    assert_not_nil assigns(:new_balance)
  end

  test "ignored transfer" do
    from_envelope = create :envelope, user: @user
    to_envelope = create :envelope, user: @user

    assert_difference('Transaction.count', 0) do
      post :create_transfer, {
        format: :js,
        transfer_amount: 'junk',
        transfer_from_id: from_envelope.id,
        transfer_to_id: to_envelope.id,
        current_envelope_id: from_envelope.id
      }
    end

    assert_response :success
    assert_nil assigns(:new_balance)
  end

  test "successful transaction update" do
    envelope = create :envelope, user: @user
    txn = create :transaction, envelope: envelope

    put :update, {
      id: txn.id,
      transaction: {amount: '$0.88'}
    }

    assert_response :success
    assert_equal 0.88, Transaction.find(txn.id).amount
  end

  test "failed transaction update" do
    envelope = create :envelope, user: @user
    txn = create :transaction, envelope: envelope

    put :update, {
      id: txn.id,
      transaction: {posted_at: nil}
    }

    assert_response :unprocessable_entity
  end

  test "payee suggestions" do
    envelope = create :envelope, user: @user
    txn = create :transaction, envelope: envelope, payee: 'Walmart'

    get :suggest_payee, {term: 'al'}

    assert_response :success
    assert @response.body.include?(txn.payee), "#{txn.payee} should be a suggestion for 'al'"
  end
end
