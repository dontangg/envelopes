
FactoryGirl.define do
  factory :envelope do
    name 'Groceries'

    user

    factory :income_envelope do
      name 'Available Cash'
      income true
    end

    factory :unassigned_envelope do
      name 'Unassigned'
      unassigned true
    end

    factory :envelope_with_transactions do
      ignore do
        transactions_count 4
      end

      after_create do |envelope, evaluator|
        FactoryGirl.create_list(:transaction, evaluator.transactions_count, envelope: envelope)
      end
    end
  end
end

