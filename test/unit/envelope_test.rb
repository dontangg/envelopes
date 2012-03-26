require 'test_helper'

class EnvelopeTest < ActiveSupport::TestCase
  def setup_envelopes
    income_envelope = FactoryGirl.create(:income_envelope)
    user = income_envelope.user
    @user_id = user.id
    FactoryGirl.create(:unassigned_envelope, user: user)
    FactoryGirl.create(:auto_envelope, user: user)
  end
  
  test "income scope should return income envelopes" do
    setup_envelopes
    envelope = User.find(@user_id).envelopes.income.first
    
    assert_equal "Available Cash", envelope.name
    assert envelope.parent_envelope_id.nil?, "The income envelope should not have a parent envelope"
    assert envelope.income?
    assert !envelope.unassigned?
  end
  
  test "unassigned scope should return unassigned envelopes" do
    setup_envelopes
    envelope = User.find(@user_id).envelopes.unassigned.first
    
    assert "Unassigned", envelope.name
    assert envelope.parent_envelope_id.nil?, "The unassigned envelope should not have a parent envelope"
    assert !envelope.income?
    assert envelope.unassigned?
  end
  
  test "generic scope should return generic envelopes" do
    setup_envelopes
    envelopes = User.find(@user_id).envelopes.generic

    assert !envelopes.empty?, "Can't do a proper test without any generic envelopes"
    
    envelopes.each do |envelope|
      assert !envelope.income?, "Generic envelopes are not income envelopes"
      assert !envelope.unassigned?, "Generic envelopes are not unassigned envelopes"
    end
  end
  
  test "parent_envelope returns the parent envelope" do
    auto_envelope = FactoryGirl.create(:envelope, name: 'Auto')
    fuel_envelope = FactoryGirl.create(:envelope, name: 'Fuel', user: auto_envelope.user, parent_envelope: auto_envelope)
    
    assert_equal auto_envelope, fuel_envelope.parent_envelope
  end

  test "child_envelopes returns the child envelopes" do
    auto_envelope = FactoryGirl.create(:envelope, name: 'Auto')
    fuel_envelope = FactoryGirl.create(:envelope, name: 'Fuel', user: auto_envelope.user, parent_envelope: auto_envelope)

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
  
  test "to_param returns name.parameterize" do
    auto_envelope = FactoryGirl.create(:envelope, name: 'Available Cash')
    
    assert_equal "available-cash", auto_envelope.to_param
  end
  
  test "transactions scope returns all transactions and child transactions for this envelope" do
    # Create envelopes
    gifts_envelope = FactoryGirl.create(:envelope, name: 'Gifts')
    holidays_envelope = FactoryGirl.create(:envelope, name: 'Holidays', user: gifts_envelope.user, parent_envelope: gifts_envelope)
    christmas_envelope = FactoryGirl.create(:envelope, name: 'Christmas', user: gifts_envelope.user, parent_envelope: holidays_envelope)

    # Create transactions
    FactoryGirl.create(:transaction)

    transactions = gifts_envelope.all_transactions(Date.today - 1.month)

    assert_equal 3, transactions.size
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
    gifts_envelope = FactoryGirl.create(:envelope, name: 'Gifts')
    holidays_envelope = FactoryGirl.create(:envelope, name: 'Holidays', user: gifts_envelope.user, parent_envelope: gifts_envelope)
    christmas_envelope = FactoryGirl.create(:envelope, name: 'Christmas', user: gifts_envelope.user, parent_envelope: holidays_envelope)

    assert_equal "Gifts", gifts_envelope.full_name
    assert_equal "Gifts: Holidays", holidays_envelope.full_name
    assert_equal "Gifts: Holidays: Christmas", christmas_envelope.full_name
  end
  
  test "self_and_child_envelope_ids returns an array of all child envelope ids" do
    auto_envelope = FactoryGirl.create(:envelope, name: 'Auto')
    fuel_envelope = FactoryGirl.create(:envelope, name: 'Fuel', user: auto_envelope.user, parent_envelope: auto_envelope)

    child_envelope_ids = auto_envelope.self_and_child_envelope_ids
    assert_equal [auto_envelope.id, fuel_envelope.id], child_envelope_ids
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

  test "creating an envelope as a child of an envelope without transactions doesn't crash" do
    auto_envelope = envelopes(:auto)

    assert_equal 0, auto_envelope.transactions.count
    
    new_envelope = Envelope.create name: 'newtest', parent_envelope: auto_envelope
  end

  test "attempting to destroy an envelope with transactions should fail" do
    groceries_envelope = envelopes(:groceries)
    num_transactions = groceries_envelope.transactions.count 

    assert num_transactions > 0

    assert !groceries_envelope.destroy
  end

  test "attempting to destroy an envelope without transactions should succeed" do
    auto_envelope = envelopes(:auto)
    num_transactions = auto_envelope.transactions.count 

    assert_equal 0, num_transactions

    assert auto_envelope.destroy
  end

end
