require 'test_helper'

class TransactionTest < ActiveSupport::TestCase
  test "uniq_str generates the correct unique string" do
    txn = transactions(:ancestry)
    
    assert_equal txn.unique_id, txn.uniq_str
  end
  
  test "owned_by returns transactions in envelopes owned by the right user" do
    txns = Transaction.owned_by(users(:jim))
    
    assert_equal 3, txns.size
  end
  
  test "envelope_id must be present before saving" do
    txn = Transaction.new payee: "t", original_payee: "tt", posted_at: Date.today, amount: 1.0
    txn.save
    
    assert !txn.valid?
  end
  
  test "transactions are ordered by posted_at, then original payee, then amount" do
    transaction0 = Transaction.new original_payee: 'bbb', amount: 2, posted_at: Date.parse('Dec 25, 2011')
    transaction1 = Transaction.new original_payee: 'bbb', amount: 3, posted_at: Date.parse('Dec 25, 2011')
    transaction2 = Transaction.new original_payee: 'ccc', amount: 2, posted_at: Date.parse('Dec 25, 2011')
    transaction3 = Transaction.new original_payee: 'bbb', amount: 2, posted_at: Date.parse('Dec 26, 2011')

    # Mix them up
    transactions = [transaction0, transaction1, transaction2, transaction3].sort_by! { Random.rand }

    # Sort them
    transactions.sort!

    assert_equal transaction0, transactions[0]
    assert_equal transaction1, transactions[1]
    assert_equal transaction2, transactions[2]
    assert_equal transaction3, transactions[3]
    assert_not_equal transaction1, transactions[0]
  end
end
