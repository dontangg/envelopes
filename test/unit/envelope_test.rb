require 'test_helper'

class EnvelopeTest < ActiveSupport::TestCase
  test "the default order should be alphabetically, by name" do
    create :envelope, name: 'Jack'
    create :envelope, name: 'Emily'
    create :envelope, name: 'Huck'

    prev_name = ""
    Envelope.all.each do |envelope|
      assert prev_name < envelope.name
      prev_name = envelope.name
    end
  end

  test "owned_by scope should return envelopes owned by the user specified" do
    env = create :envelope
    create :envelope, user: env.user
    envelopes = Envelope.owned_by(env.user.id)
  
    envelopes.each do |envelope|
      assert_equal env.user.id, envelope.user_id, "owned_by(#{env.user.id}) should only return envelopes owned by user #{env.user.id}"
    end
  end

  test "income scope should return income envelopes" do
    create :income_envelope
    envelopes = Envelope.income
    
    envelopes.each do |envelope|
      assert envelope.income?
    end
  end
  
  test "unassigned scope should return unassigned envelopes" do
    create :unassigned_envelope
    envelope = Envelope.unassigned
    
    envelopes.each do |envelope|
      assert envelope.unassigned?
    end
  end
  
  test "generic scope should return generic envelopes" do
    create :envelope
    create :income_envelope
    create :unassigned_envelope
    envelopes = Envelope.generic
    
    envelopes.each do |envelope|
      assert !envelope.income?
      assert !envelope.unassigned?
    end
  end
  
  test "parent_envelope returns the parent envelope" do
    parent = create :envelope
    child = create :envelope, user: parent.user, parent_envelope_id: parent.id
    
    assert_equal parent.id, child.parent_envelope.id
  end

  test "child_envelopes returns the child envelopes" do
    parent = create :envelope
    child = create :envelope, user: parent.user, parent_envelope: parent

    assert parent.child_envelopes do |envelope|
      assert_equal parent.id, envelope.parent_envelope_id
    end
  end

  test "with_amounts returns all envelopes with their total amounts" do
    fuel = create :envelope, name: 'Fuel'
    groceries = create :envelope, name: 'Groceries', user: fuel.user
    mortgage = create :envelope, name: 'Mortgage', user: fuel.user

    create :transaction, envelope: fuel, amount: 1.11
    create :transaction, envelope: groceries, amount: 2.22
    create :transaction, envelope: mortgage, amount: 3.33

    all_envelopes = Envelope.with_amounts

    fuel = all_envelopes.select { |envelope| envelope.id == fuel.id }.first
    assert_not_nil fuel
    assert_equal 1.11, fuel.read_attribute(:total_amount)

    groceries = all_envelopes.select { |envelope| envelope.id == groceries.id }.first
    assert_not_nil groceries
    assert_equal 2.22, groceries.read_attribute(:total_amount)

    mortgage = all_envelopes.select { |envelope| envelope.id == mortgage.id }.first
    assert_not_nil mortgage
    assert_equal 3.33, mortgage.read_attribute(:total_amount)
  end

  test "add_funded_this_month gets the amount funded for all envelopes" do
    fuel = create :envelope, name: 'Fuel'
    groceries = create :envelope, name: 'Groceries', user: fuel.user
    other = create :envelope, name: 'Other', user: fuel.user

    create :transaction, envelope: fuel, amount: -5.0
    create :transaction, envelope: fuel, amount: 7.0
    create :transaction, envelope: groceries, amount: 6.0

    all_envelopes = Envelope.all
    Envelope.add_funded_this_month(all_envelopes, fuel.user.id)

    fuel = all_envelopes.select { |envelope| envelope.id == fuel.id }.first
    assert_equal 7.0, fuel.instance_variable_get(:@amount_funded_this_month)
    groceries = all_envelopes.select { |envelope| envelope.id == groceries.id }.first
    assert_equal 6.0, groceries.instance_variable_get(:@amount_funded_this_month)
    other = all_envelopes.select { |envelope| envelope.id == other.id }.first
    assert_equal 0.0, other.instance_variable_get(:@amount_funded_this_month)
  end

  test "all_envelope returns an envelope that represents all transactions" do
    all = Envelope.all_envelope
    assert_equal 0, all.id

    all = Envelope.all_envelope(5.43)
    assert_equal 0, all.id
    assert_equal 5.43, all.total_amount
  end

  test "can organize envelope into groups and sort envelopes by full name" do
    income = create :income_envelope
    unassigned = create :unassigned_envelope, user: income.user
    parent = create :envelope, user: income.user, name: 'Food'
    child = create :envelope, user: income.user, parent_envelope: parent, name: 'Groceries'

    all_envelopes = [unassigned, income, child, parent]
    organized_envelopes = Envelope.organize(all_envelopes)

    assert organized_envelopes['sys'].include?(income)
    assert organized_envelopes['sys'].include?(unassigned)
    assert organized_envelopes['sys'].any? {|env| env.id == 0 }
    assert_equal [parent], organized_envelopes[nil], "There should be a group containing all top-level envelopes"
    assert_equal [child], organized_envelopes[parent.id]

    assert_equal income, all_envelopes[0], "the original array wasn't sorted correctly"
    assert_equal parent, all_envelopes[1], "the original array wasn't sorted correctly"
    assert_equal child, all_envelopes[2], "the original array wasn't sorted correctly"
    assert_equal unassigned, all_envelopes[3], "the original array wasn't sorted correctly"
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
    envelope = create :envelope, name: 'Available Cash'
    
    assert_equal "#{envelope.id}-available-cash", envelope.to_param
  end
  
  test "transactions scope returns all transactions for this envelope" do
    envelope = create :envelope_with_transactions, transactions_count: 6
    assert_equal 6, envelope.transactions.size

    envelope = create :envelope_with_transactions, transactions_count: 3
    assert_equal 3, envelope.transactions.size
  end
  
  test "total_amount returns sum of all transactions" do
    envelope = create :envelope
    create :transaction, envelope: envelope, amount: 1.0
    create :transaction, envelope: envelope, amount: -2.22

    assert_equal -1.22, envelope.total_amount
  end

  test "inclusive_total_amount returns sum of all transactions" do
    parent = create :envelope
    child1 = create :envelope, user: parent.user, parent_envelope_id: parent.id
    create :transaction, envelope: child1, amount: 2.0
    child2 = create :envelope, user: parent.user, parent_envelope_id: parent.id
    create :transaction, envelope: child2, amount: -3.33

    assert_equal 0.0, parent.total_amount
    assert_equal -1.33, parent.inclusive_total_amount
  end

  test "full_name returns this and parent envelope names separated by colons" do
    food_envelope = create :envelope, name: 'Food'
    assert_equal "Food", food_envelope.full_name
    
    groceries_envelope = create :envelope, name: 'Groceries', user: food_envelope.user, parent_envelope: food_envelope
    assert_equal "Food: Groceries", groceries_envelope.full_name
  end

  test "can calculate a simple budget for this envelope" do
    envelope = build :envelope, expense: nil
    assert_equal 0.0, envelope.simple_monthly_budget

    envelope.expense = Expense.new(frequency: :monthly, amount: 12.0)
    assert_equal 12.0, envelope.simple_monthly_budget

    envelope.expense.frequency = :yearly
    assert_equal 1.0, envelope.simple_monthly_budget
  end
  
  test "all_child_envelope_ids returns an array of all child envelope ids" do
    parent = create :envelope
    child1 = create :envelope, user: parent.user, parent_envelope_id: parent.id
    child2 = create :envelope, user: parent.user, parent_envelope_id: parent.id

    child_envelope_ids = Envelope.all_child_envelope_ids(parent.id)
    assert_equal [child1.id, child2.id], child_envelope_ids
  end
  
  test "all_transactions returns all transactions for that envelope and all children" do
    parent = create :envelope
    child1 = create :envelope, user: parent.user, parent_envelope_id: parent.id
    child2 = create :envelope, user: parent.user, parent_envelope_id: parent.id
    txn1 = create :transaction, envelope: child1
    txn2 = create :transaction, envelope: child2

    all_txns = parent.all_transactions(nil)
    assert all_txns.any? { |txn| txn.id == txn1.id }
    assert all_txns.any? { |txn| txn.id == txn2.id }
  end

  test "amount_funded_this_month returns a sum of the positive transaction amounts" do
    envelope = create :envelope
    txn1 = create :transaction, envelope: envelope, amount: -20.0
    txn2 = create :transaction, envelope: envelope, amount: 100.0
    amount = envelope.amount_funded_this_month.to_f

    assert_equal 100.0, amount
  end

  test "amount_spent_this_month returns a sum of the negative transaction amounts" do
    envelope = create :envelope
    txn1 = create :transaction, envelope: envelope, amount: -20.0
    txn2 = create :transaction, envelope: envelope, amount: 100.0
    amount = envelope.amount_spent_this_month.to_f

    assert_equal -20.0, amount
  end

  test "creating an envelope as a child of an envelope that has transactions should move the transactions to the new child" do
    food_envelope = create :envelope, name: 'Food'
    txn1 = create :transaction, envelope: food_envelope

    num_transactions = food_envelope.transactions.count 

    assert_equal 1, num_transactions

    groceries_envelope = create :envelope, name: 'Groceries', user: food_envelope.user, parent_envelope: food_envelope

    assert_equal 1, groceries_envelope.transactions.count
    assert_equal 0, food_envelope.transactions.count
  end

  test "creating an envelope as a child of an envelope without transactions doesn't crash" do
    assert_nothing_raised do
      food_envelope = create :envelope, name: 'Food'
      groceries_envelope = create :envelope, name: 'Groceries', user: food_envelope.user, parent_envelope: food_envelope
    end
  end

  test "attempting to destroy an envelope with transactions should fail" do
    food_envelope = create :envelope, name: 'Food'
    create :transaction, envelope: food_envelope

    assert_equal 1, food_envelope.transactions.count 

    assert !food_envelope.destroy
  end

  test "attempting to destroy an envelope without transactions should succeed" do
    food_envelope = create :envelope, name: 'Food'

    assert_equal 0, food_envelope.transactions.count 

    assert food_envelope.destroy
  end

end
