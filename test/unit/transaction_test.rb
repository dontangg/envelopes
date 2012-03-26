require 'test_helper'

class TransactionTest < ActiveSupport::TestCase
  test "uniq_str generates the correct unique string" do
    txn = FactoryGirl.create(:transaction, payee: 'payee with space', original_payee: 'original  payee  ', amount: 1.23, posted_at: Date.new(2012, 3, 26), unique_count: 1)
    
    assert_equal "2012-03-26~original payee~1.23~false~", txn.uniq_str
  end
  
  test "posted_at, payee, original_payee, and amount must be present before saving" do
    txn = FactoryGirl.build(:transaction, posted_at: nil)
    assert !txn.save, txn.errors.full_messages.join
    txn.posted_at = Date.today
    assert txn.save, txn.errors.full_messages.join

    txn = FactoryGirl.build(:transaction, payee: nil)
    assert !txn.save, txn.errors.full_messages.join
    txn.payee = "payee"
    assert txn.save, txn.errors.full_messages.join

    txn = FactoryGirl.build(:transaction, original_payee: nil)
    assert !txn.save, txn.errors.full_messages.join
    txn.original_payee = "original payee"
    assert txn.save, txn.errors.full_messages.join

    txn = FactoryGirl.build(:transaction, amount: nil)
    assert !txn.save, txn.errors.full_messages.join
    txn.amount = 1.23
    assert txn.save, txn.errors.full_messages.join
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
  
  test "without_transfers excludes transactions with a nil unique_count" do
    group = FactoryGirl.create(:transaction_group_with_transactions)
    transactions = group.transactions.without_transfers

    assert transactions.size > 0, "Can't do a proper test without any transactions"
    assert transactions.size != group.transactions.size, "Can't do a proper test without normal and transfer transactions"
    transactions.each do |transaction|
      assert_not_nil transaction.unique_count
    end
  end

  test "transactions should be read in the right order" do
    group = FactoryGirl.create(:transaction_group)

    FactoryGirl.create(:transaction, transaction_group: group, posted_at: Date.today - 1.day)
    FactoryGirl.create(:transaction, transaction_group: group, posted_at: Date.today)
    FactoryGirl.create(:transaction, transaction_group: group, posted_at: Date.today - 3.days)
    FactoryGirl.create(:transaction, transaction_group: group, posted_at: Date.today - 2.days)

    # Read the user to get the order right
    group = TransactionGroup.find(group.id)

    prev_date = Date.today + 1.day
    group.transactions.each do |txn|
      assert prev_date > txn.posted_at, "Transactions should be ordered by date descending (#{prev_date} <= #{txn.posted_at})"
      prev_date = txn.posted_at
    end
  end

  test "should strip the whitespace off the payee before save" do
    txn = FactoryGirl.create(:transaction, payee: "\t\n lots of\n whitespace \t\n")

    assert_equal "lots of\n whitespace", txn.payee
  end

end
