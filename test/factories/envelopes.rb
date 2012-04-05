
FactoryGirl.define do
  factory :envelope do
    name 'Groceries'

    user

    factory :envelope_with_transactions do
      after_create do |envelope, evaluator|
        FactoryGirl.create_list(:transaction, 4, envelope: envelope)
      end
    end
  end
end

