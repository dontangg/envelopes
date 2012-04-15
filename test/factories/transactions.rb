
FactoryGirl.define do
  factory :transaction do
    posted_at Date.today
    payee 'Best Buy'
    sequence(:original_payee) { |n| "1239465 BEST BUY USA #{n}" }
    amount 1.23
    pending false
    unique_id { uniq_str }

    envelope

    trait :transfer do
      unique_id nil
    end

    factory :transfer_transaction do
      payee 'Transferred money from another envelope'
      original_payee 'Transferred money from another envelope'
      transfer
    end
  end
end

