
FactoryGirl.define do
  factory :transaction do
    posted_at Date.today
    payee 'Best Buy'
    sequence(:original_payee) { |n| "1239465 BEST BUY USA #{n}" }
    amount 1.23
    pending false
    unique_id { uniq_str }
    envelope

    factory :transfer_transaction do
      payee 'Transferred money from another envelope'
      original_payee 'Transferred money from another envelope'
      unique_id nil
    end
  end
end

