
FactoryGirl.define do
  factory :rule do
    search_text 'WALMART'
    replacement_text 'Walmart'
    order 0

    association :user
    association :envelope
  end
end

