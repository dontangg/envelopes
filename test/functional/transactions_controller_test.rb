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
end