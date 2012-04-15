
FactoryGirl.define do
  factory :rule do
    search_text 'WALMART'
    replacement_text 'Walmart'
    order 0

    user
    envelope
  end
end

