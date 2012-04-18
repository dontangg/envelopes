require 'test_helper'

class TransactionTest < ActiveSupport::TestCase
  test "uniq_str generates the correct unique string" do
    txn = build :transaction

    assert_equal "#{Date.today.strftime('%F')}~#{txn.original_payee}~#{txn.amount}~#{txn.pending?}~", txn.uniq_str
  end

  test "owned_by returns transactions in envelopes owned by the right user" do
    envelope = create :envelope_with_transactions
    create :envelope_with_transactions, user: envelope.user
    create :envelope_with_transactions

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
    create_list :transfer_transaction, 3
    create_list :transaction, 3

    transactions = Transaction.without_transfers

    assert transactions.size > 0, "Can't do a proper test without any transactions"
    assert transactions.size != Transaction.count, "Can't do a proper test without normal and transfer transactions"
    transactions.each do |transaction|
      assert_not_nil transaction.unique_id
    end
  end

  test "associated transaction amounts stay in sync" do
    txn1 = create :transfer_transaction, amount: 15.01
    txn2 = create :transfer_transaction, amount: txn1.amount * -1, associated_transaction_id: txn1.id
    txn1.update_attribute :associated_transaction_id, txn2.id

    assert txn1.amount == (txn2.amount * -1)

    txn1.update_attribute :amount, 25

    txn2 = Transaction.find(txn2.id)

    assert_equal -25, txn2.amount
  end

  test "should strip whitespace from payee before save" do
    txn = create :transaction, payee: ' my payee  '

    assert_equal 'my payee', txn.payee
  end

  test "should return transactions starting_at a date" do
    txn1 = create :transaction, posted_at: Date.today
    txn2 = create :transaction, posted_at: Date.today - 1, envelope: txn1.envelope

    txns = Transaction.starting_at Date.today

    assert txns.all? { |txn| txn.posted_at >= Date.today }
    assert txns.any? { |txn| txn.id == txn1.id }
    assert txns.none? { |txn| txn.id == txn2.id }
  end

  test "should return transactions ending_at a date" do
    txn1 = create :transaction, posted_at: Date.today
    txn2 = create :transaction, posted_at: Date.today - 1, envelope: txn1.envelope

    txns = Transaction.ending_at(Date.today - 1)

    assert txns.all? { |txn| txn.posted_at <= Date.today - 1 }
    assert txns.any? { |txn| txn.id == txn2.id }
    assert txns.none? { |txn| txn.id == txn1.id }
  end

  test "should give valid payee suggestions" do
    txn1 = create :transaction, payee: 'an awesome store'
    txn2 = create :transaction, payee: 'a great store', envelope: txn1.envelope
    txn3 = create :transaction, payee: '1234 STORE USA', original_payee: '1234 STORE USA', envelope: txn1.envelope

    suggestions = Transaction.payee_suggestions_for_user_id(txn1.envelope.user.id, 'store')
    assert suggestions.size > 0, "There must be some suggestions to test"

    suggestions.each do |sugg|
      assert (sugg =~ /store/i), "Each suggestion for 'store' should include the word 'store' (suggestion: '#{sugg}')"
    end

    assert suggestions.include?(txn1.payee), "#{txn1.payee} should be a suggestion"
    assert suggestions.include?(txn2.payee), "#{txn1.payee} should be a suggestion"
    assert !suggestions.include?(txn3.payee), "#{txn1.payee} should NOT be a suggestion"
  end

  test "should suggest payees with fuzzy matches" do
    txn1 = create :transaction, payee: 'an awesome store'

    suggestions = Transaction.payee_suggestions_for_user_id(txn1.envelope.user.id, 'awe store')
    assert suggestions.size > 0, "There must be some suggestions to test"

    assert suggestions.include?(txn1.payee)
  end

  test "should give valid original payee suggestions" do
    txn1 = create :transaction, original_payee: '2345 DOLLAR STORE'
    txn2 = create :transaction, original_payee: '1357 BOAT STORE', envelope: txn1.envelope
    txn3 = create :transaction, original_payee: '1234 STORE USA', envelope: txn1.envelope

    suggestions = Transaction.payee_suggestions_for_user_id(txn1.envelope.user.id, 'store', true)
    assert suggestions.size > 0, "There must be some suggestions to test"

    suggestions.each do |sugg|
      assert (sugg =~ /store/i), "Each suggestion for 'store' should include the word 'store' (suggestion: '#{sugg}')"
    end

    assert suggestions.include?(txn1.original_payee), "#{txn1.original_payee} should be a suggestion"
    assert suggestions.include?(txn2.original_payee), "#{txn2.original_payee} should be a suggestion"
    assert suggestions.include?(txn3.original_payee), "#{txn3.original_payee} should be a suggestion"
  end

  test "can create a transfer" do
    from_envelope = create :envelope
    to_envelope = create :envelope, user: from_envelope.user

    from_sum = from_envelope.total_amount
    to_sum = to_envelope.total_amount

    txn = Transaction.create_transfer 4.56, from_envelope.id, to_envelope.id, "Transferred from ...", "Transferred to ..."

    assert txn.associated_transaction_id.present?, "Transfer transactions should have an associated transaction"
    assert txn.amount == -txn.associated_transaction.amount, "Associated transaction amount should equal -amount"

    from_envelope.total_amount = nil
    to_envelope.total_amount = nil

    assert from_envelope.total_amount = from_sum + txn.amount, "New envelope total should have changed"
    assert to_envelope.total_amount = to_sum - txn.amount, "New envelope total should have changed"
  end
end
