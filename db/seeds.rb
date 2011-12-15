# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

case Rails.env
when "development"

  puts "-- creating users"

  test_user = User.create email: 'test@gmail.com', password: 'pass'


  puts "-- creating envelopes"

  auto_envelope = Envelope.create name: 'Auto', user: test_user
  fuel_envelope = Envelope.create name: "Fuel", user: test_user, parent_envelope: auto_envelope
  auto_maintenance_envelope = Envelope.create name: "Maintenance", user: test_user, parent_envelope: auto_envelope

  bills_envelope = Envelope.create name: 'Bills', user: test_user
  car_insurance_envelope = Envelope.create name: "Car Insurance", user: test_user, parent_envelope: bills_envelope
  student_loans_envelope = Envelope.create name: "Student Loans", user: test_user, parent_envelope: bills_envelope
  life_insurance_envelope = Envelope.create name: "Life Insurance", user: test_user, parent_envelope: bills_envelope
  mortgage_envelope = Envelope.create name: "Mortgage", user: test_user, parent_envelope: bills_envelope
  credit_card_envelope = Envelope.create name: "Credit Card", user: test_user, parent_envelope: bills_envelope
  
  entertainment_envelope = Envelope.create name: 'Entertainment', user: test_user
  apple_envelope = Envelope.create name: "Apple", user: test_user, parent_envelope: entertainment_envelope
  other_entertainment_envelope = Envelope.create name: "Other", user: test_user, parent_envelope: entertainment_envelope

  food_envelope = Envelope.create name: 'Food', user: test_user
  eating_out_envelope = Envelope.create name: "Eating Out", user: test_user, parent_envelope: food_envelope
  groceries_envelope = Envelope.create name: "Groceries", user: test_user, parent_envelope: food_envelope

  gifts_envelope = Envelope.create name: 'Gifts & Donations', user: test_user
  birthdays_envelope = Envelope.create name: 'Birthdays', user: test_user, parent_envelope: gifts_envelope
  Envelope.create name: "Don", user: test_user, parent_envelope: birthdays_envelope
  Envelope.create name: "Mandi", user: test_user, parent_envelope: birthdays_envelope
  Envelope.create name: "Robbie", user: test_user, parent_envelope: birthdays_envelope
  Envelope.create name: "Luke", user: test_user, parent_envelope: birthdays_envelope
  Envelope.create name: "Others", user: test_user, parent_envelope: birthdays_envelope
  holidays_envelope = Envelope.create name: 'Holidays', user: test_user, parent_envelope: gifts_envelope
  Envelope.create name: "Christmas", user: test_user, parent_envelope: holidays_envelope
  Envelope.create name: "Easter", user: test_user, parent_envelope: holidays_envelope
  Envelope.create name: "Halloween", user: test_user, parent_envelope: holidays_envelope
  Envelope.create name: "Valentine's Day", user: test_user, parent_envelope: holidays_envelope

  subscriptions_envelope = Envelope.create name: 'Subscriptions', user: test_user
  domains_envelope = Envelope.create name: 'Domains', user: test_user, parent_envelope: subscriptions_envelope
  netflix_envelope = Envelope.create name: 'Netflix', user: test_user, parent_envelope: subscriptions_envelope
  
  
  puts "-- creating transactions"
  Transaction.create payee: "Wal-Mart", original_payee: '20397235 WALMART AS2385 SPRINGVILLE, UT', unique_id: 'WALMART-3', posted_at: Date.today - 5.days, amount: -25.64, envelope: groceries_envelope
  Transaction.create payee: "Target", original_payee: '20397235 TARGET AS2385 OREM, UT', unique_id: 'TARGET-3', posted_at: Date.today - 4.days, amount: -39.29, envelope: groceries_envelope
  Transaction.create payee: "Wendy's", original_payee: '20397235 WENDYS AS2385 OREM, UT', unique_id: 'WENDYS-3', posted_at: Date.today - 3.days, amount: -4.56, envelope: eating_out_envelope
  Transaction.create payee: "Funded envelope", original_payee: 'Funded envelope', posted_at: Date.today - 1.days, amount: 100, envelope: eating_out_envelope
  

  puts "-- creating rules"
  Rule.create search_text: "WALMART", replacement_text: "Wal-Mart", envelope: groceries_envelope, user: test_user, order: 1
  Rule.create search_text: "COSTCO GAS", replacement_text: "CostCo Gas", envelope: fuel_envelope, user: test_user, order: 2
  Rule.create search_text: "COSTCO", replacement_text: "CostCo", envelope: groceries_envelope, user: test_user, order: 3
end
