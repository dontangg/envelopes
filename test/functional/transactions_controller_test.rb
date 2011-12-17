require 'test_helper'

class TransactionsControllerTest < ActionController::TestCase
  setup do
    login_as :jim
  end

  test "successful transfer" do
    from_envelope = envelopes(:groceries)
    to_envelope = envelopes(:christmas)

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
    from_envelope = envelopes(:groceries)
    to_envelope = envelopes(:christmas)

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
    txn = transactions(:walmart)

    put :update, {
      id: txn.id,
      transaction: {amount: '$0.88'}
    }

    assert_response :success
    assert_equal 0.88, Transaction.find(txn.id).amount
  end

  test "failed transaction update" do
    txn = transactions(:walmart)

    put :update, {
      id: txn.id,
      transaction: {posted_at: nil}
    }

    assert_response :unprocessable_entity
  end

  test "payee suggestions" do
    get :suggest_payee, {term: 'al'}

    assert_response :success
    assert @response.body.include?(transactions(:walmart).payee), transactions(:walmart).payee + " should be a suggestion for 'al'"
  end
end