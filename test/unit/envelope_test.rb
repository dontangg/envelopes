require 'test_helper'

class EnvelopeTest < ActiveSupport::TestCase
  test "owned_by scope should return envelopes owned by the user specified" do
    env = FactoryGirl.create :envelope
    FactoryGirl.create :envelope, user: env.user
    envelopes = Envelope.owned_by(env.user.id)
  
    envelopes.each do |envelope|
      assert_equal env.user.id, envelope.user_id, "owned_by(#{env.user.id}) should only return envelopes owned by user #{env.user.id}"
    end
  end

  test "income scope should return income envelopes" do
    FactoryGirl.create :income_envelope
    envelopes = Envelope.income
    
    envelopes.each do |envelope|
      assert envelope.income?
    end
  end
  
  test "unassigned scope should return unassigned envelopes" do
    FactoryGirl.create :unassigned_envelope
    envelope = Envelope.unassigned
    
    envelopes.each do |envelope|
      assert envelope.unassigned?
    end
  end
  
  test "generic scope should return generic envelopes" do
    FactoryGirl.create :envelope
    FactoryGirl.create :income_envelope
    FactoryGirl.create :unassigned_envelope
    envelopes = Envelope.generic
    
    envelopes.each do |envelope|
      assert !envelope.income?
      assert !envelope.unassigned?
    end
  end
  
  test "parent_envelope returns the parent envelope" do
    parent = FactoryGirl.create :envelope
    child = FactoryGirl.create :envelope, user: parent.user, parent_envelope: parent
    
    assert_equal parent.id, child.parent_envelope.id
  end

  test "child_envelopes returns the child envelopes" do
    parent = FactoryGirl.create :envelope
    child = FactoryGirl.create :envelope, user: parent.user, parent_envelope: parent

    assert parent.child_envelopes do |envelope|
      assert_equal parent.id, envelope.parent_envelope_id
    end
  end

  test "initialize can accept a Hash for the expense" do
    new_envelope = Envelope.new({
      name: 'test',
      user_id: 100,
      expense: {
        amount: 12.34,
        occurs_on_day: 3,
        frequency: :yearly
      }
    })

    assert_not_nil new_envelope
    assert_equal 'test', new_envelope.name
    assert_not_nil new_envelope.expense
    assert_equal 12.34, new_envelope.expense.amount
    assert_equal :yearly, new_envelope.expense.frequency
  end
  
  test "to_param returns id-name.parameterize" do
    envelope = FactoryGirl.create :envelope, name: 'Available Cash'
    
    assert_equal "#{envelope.id}-available-cash", envelope.to_param
  end
  
  test "transactions scope returns all transactions for this envelope" do
    envelope = FactoryGirl.create :envelope_with_transactions, transactions_count: 6
    assert_equal 6, envelope.transactions.size

    envelope = FactoryGirl.create :envelope_with_transactions, transactions_count: 3
    assert_equal 3, envelope.transactions.size
  end
  
  test "total_amount returns sum of all transactions" do
    envelope = FactoryGirl.create :envelope
    FactoryGirl.create :transaction, envelope: envelope, amount: 1.0
    FactoryGirl.create :transaction, envelope: envelope, amount: -2.22

    assert_equal -1.22, envelope.total_amount
  end

  test "inclusive_total_amount returns sum of all transactions" do
    parent = FactoryGirl.create :envelope
    child1 = FactoryGirl.create :envelope, user: parent.user, parent_envelope_id: parent.id
    FactoryGirl.create :transaction, envelope: child1, amount: 2.0
    child2 = FactoryGirl.create :envelope, user: parent.user, parent_envelope_id: parent.id
    FactoryGirl.create :transaction, envelope: child2, amount: -3.33

    assert_equal 0.0, parent.total_amount
    assert_equal -1.33, parent.inclusive_total_amount
  end

  test "full_name returns this and parent envelope names separated by colons" do
    food_envelope = FactoryGirl.create :envelope, name: 'Food'
    assert_equal "Food", food_envelope.full_name
    
    groceries_envelope = FactoryGirl.create :envelope, name: 'Groceries', user: food_envelope.user, parent_envelope: food_envelope
    assert_equal "Food: Groceries", groceries_envelope.full_name
  end
  
  test "all_child_envelope_ids returns an array of all child envelope ids" do
    parent = FactoryGirl.create :envelope
    child1 = FactoryGirl.create :envelope, user: parent.user, parent_envelope_id: parent.id
    child2 = FactoryGirl.create :envelope, user: parent.user, parent_envelope_id: parent.id

    child_envelope_ids = Envelope.all_child_envelope_ids(parent.id)
    assert_equal [child1.id, child2.id], child_envelope_ids
  end
  
  test "all_transactions returns all transactions for that envelope and all children" do
    parent = FactoryGirl.create :envelope
    child1 = FactoryGirl.create :envelope, user: parent.user, parent_envelope_id: parent.id
    child2 = FactoryGirl.create :envelope, user: parent.user, parent_envelope_id: parent.id
    txn1 = FactoryGirl.create :transaction, envelope: child1
    txn2 = FactoryGirl.create :transaction, envelope: child2

    all_txns = parent.all_transactions(nil)
    assert all_txns.any? { |txn| txn.id == txn1.id }
    assert all_txns.any? { |txn| txn.id == txn2.id }
  end

  test "amount_funded_this_month returns a sum of the positive transaction amounts" do
    envelope = FactoryGirl.create :envelope
    txn1 = FactoryGirl.create :transaction, envelope: envelope, amount: -20.0
    txn2 = FactoryGirl.create :transaction, envelope: envelope, amount: 100.0
    amount = envelope.amount_funded_this_month.to_f

    assert_equal 100.0, amount
  end

  test "creating an envelope as a child of an envelope that has transactions should move the transactions to the new child" do
    food_envelope = FactoryGirl.create :envelope, name: 'Food'
    txn1 = FactoryGirl.create :transaction, envelope: food_envelope

    num_transactions = food_envelope.transactions.count 

    assert_equal 1, num_transactions

    groceries_envelope = FactoryGirl.create :envelope, name: 'Groceries', user: food_envelope.user, parent_envelope: food_envelope

    assert_equal 1, groceries_envelope.transactions.count
    assert_equal 0, food_envelope.transactions.count
  end

  test "creating an envelope as a child of an envelope without transactions doesn't crash" do
    assert_nothing_raised do
      food_envelope = FactoryGirl.create :envelope, name: 'Food'
      groceries_envelope = FactoryGirl.create :envelope, name: 'Groceries', user: food_envelope.user, parent_envelope: food_envelope
    end
  end

  test "attempting to destroy an envelope with transactions should fail" do
    food_envelope = FactoryGirl.create :envelope, name: 'Food'
    FactoryGirl.create :transaction, envelope: food_envelope

    assert_equal 1, food_envelope.transactions.count 

    assert !food_envelope.destroy
  end

  test "attempting to destroy an envelope without transactions should succeed" do
    food_envelope = FactoryGirl.create :envelope, name: 'Food'

    assert_equal 0, food_envelope.transactions.count 

    assert food_envelope.destroy
  end

end
