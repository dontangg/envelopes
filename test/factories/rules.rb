
FactoryGirl.define do
  factory :rule do
    user { FactoryGirl.build(:user) }
    search_text 'WALMART'
    replacement_text 'Walmart'
    sequence :order
    envelope_id 123
  end
end

