
FactoryGirl.define do
  factory :transfer_rule do
    search_terms 'Google, Apple'
    payee 'Pay taxes'
    percentage 28

    user
    envelope
  end
end

