require 'test_helper'

class TransactionTest < ActiveSupport::TestCase
  test "uniq_str generates the correct unique string" do
    txn = transactions(:ancestry)
    
    assert_equal txn.unique_id, txn.uniq_str
  end
  
  test "owned_by returns transactions in envelopes owned by the right user" do
    txns = Transaction.owned_by(users(:jim))
    jims_envelopes = Envelope.where(user_id: users(:jim).id).map(&:id)
    txns.each do |transaction|
      assert jims_envelopes.include?(transaction.envelope_id)
    end
  end
  
  test "envelope_id must be present before saving" do
    txn = Transaction.new payee: "t", original_payee: "tt", posted_at: Date.today, amount: 1.0
    
    assert !txn.save
    assert !txn.valid?
  end
  
  test "transactions are ordered by posted_at, then original payee, then amount" do
    transaction0 = Transaction.new original_payee: 'bbb', amount: 2, posted_at: Date.parse('Dec 25, 2011')
    transaction1 = Transaction.new original_payee: 'bbb', amount: 3, posted_at: Date.parse('Dec 25, 2011')
    transaction2 = Transaction.new original_payee: 'ccc', amount: 2, posted_at: Date.parse('Dec 25, 2011')
    transaction3 = Transaction.new original_payee: 'bbb', amount: 2, posted_at: Date.parse('Dec 26, 2011')

    # Mix them up
    transactions = [transaction0, transaction1, transaction2, transaction3].sort_by { Random.rand }

    # Sort them
    transactions.sort!

    assert_equal transaction0, transactions[0]
    assert_equal transaction1, transactions[1]
    assert_equal transaction2, transactions[2]
    assert_equal transaction3, transactions[3]
    assert_not_equal transaction1, transactions[0]
  end
  
  test "without_transfers excludes when unique_id is nil" do
    transactions = Transaction.without_transfers
    transactions.each do |transaction|
      assert_not_nil transaction.unique_id
    end
  end

  test "associated transaction amounts stay in sync" do
    transfer_to = transactions(:transfer_to_food)
    transfer_from = transfer_to.associated_transaction

    assert transfer_to.amount == (transfer_from.amount * -1)

    transfer_to.amount = 25
    transfer_to.save

    assert_equal -25, transfer_from.amount
  end
end
