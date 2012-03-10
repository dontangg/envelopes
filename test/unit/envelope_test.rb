require 'test_helper'

class EnvelopeTest < ActiveSupport::TestCase
  test "owned_by scope should return envelopes owned by the user specified" do
    envelopes = Envelope.owned_by(1)
  
    envelopes.each do |envelope|
      assert_equal 1, envelope.user_id, "owned_by(1) should only return envelopes owned by user 1"
    end
  end

  test "income scope should return income envelopes" do
    envelope = Envelope.income.first
    
    assert_equal "Available Cash", envelope.name
    assert envelope.parent_envelope_id.nil?, "The income envelope should not have a parent envelope"
    assert envelope.income?
    assert !envelope.unassigned?
  end
  
  test "unassigned scope should return unassigned envelopes" do
    envelope = Envelope.unassigned.first
    
    assert "Unassigned", envelope.name
    assert envelope.parent_envelope_id.nil?, "The unassigned envelope should not have a parent envelope"
    assert !envelope.income?
    assert envelope.unassigned?
  end
  
  test "generic scope should return generic envelopes" do
    envelopes = Envelope.generic
    
    envelopes.each do |envelope|
      assert !envelope.income?
      assert !envelope.unassigned?
    end
  end
  
  test "parent_envelope returns the parent envelope" do
    fuel_envelope = envelopes(:fuel)
    auto_envelope = envelopes(:auto)
    
    assert_equal auto_envelope, fuel_envelope.parent_envelope
  end

  test "child_envelopes returns the child envelopes" do
    fuel_envelope = envelopes(:fuel)
    auto_envelope = envelopes(:auto)

    assert auto_envelope.child_envelopes.include?(fuel_envelope)
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
    envelope = envelopes(:available_cash)
    
    assert_equal "#{envelope.id}-available-cash", envelope.to_param
  end
  
  test "transactions scope returns all transactions for this envelope" do
    food_envelope = envelopes(:food)
    assert_equal 2, food_envelope.transactions.size
    
    auto_envelope = envelopes(:auto)
    assert_equal 0, auto_envelope.transactions.size
    
    cash_envelope = envelopes(:available_cash)
    assert_equal 1, cash_envelope.transactions.size
  end
  
  test "total_amount returns sum of all transactions" do
    cash_envelope = envelopes(:available_cash)
    assert_equal 9.99, cash_envelope.total_amount
  end

  test "inclusive_total_amount returns sum of all transactions" do
    food_envelope = envelopes(:food)
    assert_equal 79.99, food_envelope.inclusive_total_amount.to_f
  end

  test "full_name returns this and parent envelope names separated by colons" do
    food_envelope = envelopes(:food)
    assert_equal "Food", food_envelope.full_name
    
    groceries_envelope = envelopes(:groceries)
    assert_equal "Food: Groceries", groceries_envelope.full_name
  end
  
  test "all_child_envelope_ids returns an array of all child envelope ids" do
    child_envelope_ids = Envelope.all_child_envelope_ids(envelopes(:gifts).id)
    assert_equal [envelopes(:holidays).id, envelopes(:christmas).id, envelopes(:valentines).id], child_envelope_ids
  end
  
  test "all_transactions returns all transactions for that envelope and all children" do
    sql = envelopes(:gifts).all_transactions(nil).to_sql
    assert sql.include?(envelopes(:gifts).id.to_s)
    assert sql.include?(envelopes(:holidays).id.to_s)
    assert sql.include?(envelopes(:christmas).id.to_s)
    assert sql.include?(envelopes(:valentines).id.to_s)
  end

  test "amount_funded_this_month returns a sum of the positive transaction amounts" do
    amount = envelopes(:groceries).amount_funded_this_month.to_f

    assert_equal 100.0, amount
  end

  test "calculate_suggestions should calculate predictable suggestions" do
    jim = users(:jim)
    all_envelopes = Envelope.owned_by(jim.id).with_amounts

    organized_envelopes = Envelope.organize(all_envelopes)

    Envelope.calculate_suggestions(organized_envelopes)

    fuel_envelope = all_envelopes.select {|envelope| envelope.id == envelopes(:fuel).id }.first
    auto_envelope = all_envelopes.select {|envelope| envelope.id == envelopes(:auto).id }.first
    christmas_envelope = all_envelopes.select {|envelope| envelope.id == envelopes(:christmas).id }.first

    assert_equal 120.0, fuel_envelope.suggested_amount
    assert_equal 120.0, auto_envelope.suggested_amount
    assert_equal 70.0, christmas_envelope.suggested_amount

  end

  test "creating an envelope as a child of an envelope that has transactions should move the transactions to the new child" do
    groceries_envelope = envelopes(:groceries)
    num_transactions = groceries_envelope.transactions.count 

    assert num_transactions > 0

    new_envelope = Envelope.create name: 'newtest', parent_envelope: groceries_envelope

    assert_equal num_transactions, new_envelope.transactions.count
    assert_equal 0, groceries_envelope.transactions.count
  end
end
