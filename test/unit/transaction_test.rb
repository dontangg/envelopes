require 'test_helper'

class TransactionTest < ActiveSupport::TestCase
  test "uniq_str generates the correct unique string" do
    txn = FactoryGirl.build :transaction
    
    assert_equal "#{Date.today.strftime('%F')}~#{txn.original_payee}~#{txn.amount}~#{txn.pending?}~", txn.uniq_str
  end
  
  test "owned_by returns transactions in envelopes owned by the right user" do
    envelope = FactoryGirl.create :envelope_with_transactions
    FactoryGirl.create :envelope_with_transactions, user: envelope.user
    FactoryGirl.create :envelope_with_transactions

    txns = Transaction.owned_by(envelope.user.id)
    users_envelopes = envelope.user.envelopes.map(&:id)
    assert txns.all? { |txn| users_envelopes.include?(txn.envelope_id) }
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
    assert_not_equal transaction1, transactions[0], "== is not testing equality correctly"
  end
  
  test "without_transfers excludes transactions with a nil unique_id" do
    FactoryGirl.create_list :transfer_transaction, 3
    FactoryGirl.create_list :transaction, 3

    transactions = Transaction.without_transfers

    assert transactions.size > 0, "Can't do a proper test without any transactions"
    assert transactions.size != Transaction.count, "Can't do a proper test without normal and transfer transactions"
    transactions.each do |transaction|
      assert_not_nil transaction.unique_id
    end
  end

  test "associated transaction amounts stay in sync" do
    txn1 = FactoryGirl.create :transfer_transaction, amount: 15.01
    txn2 = FactoryGirl.create :transfer_transaction, amount: txn1.amount * -1, associated_transaction_id: txn1.id
    txn1.update_attribute :associated_transaction_id, txn2.id

    assert txn1.amount == (txn2.amount * -1)

    txn1.update_attribute :amount, 25

    txn2 = Transaction.find(txn2.id)

    assert_equal -25, txn2.amount
  end
end
