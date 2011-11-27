require 'test_helper'

class TransactionTest < ActiveSupport::TestCase
  test "uniq_str generates the correct unique string" do
    txn = transactions(:ancestry)
    
    assert_equal txn.unique_id, txn.uniq_str
  end
  
  test "owned_by returns transactions in envelopes owned by the right user" do
    txns = Transaction.owned_by(1)
    
    assert_equal 2, txns.size
  end
  
  test "envelope_id must be present before saving" do
    txn = Transaction.new payee: "t", original_payee: "tt", posted_at: Date.today, amount: 1.0
    txn.save
    
    assert !txn.valid?
  end
  
  test "transactions are ordered by posted_at, then payee, then amount" do
    pending "finish this"
  end
end
