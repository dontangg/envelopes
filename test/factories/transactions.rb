
FactoryGirl.define do
  factory :transaction do
    posted_at Date.today
    payee 'Best Buy'
    original_payee '1239465 BEST BUY USA'
    amount 1.23
    pending false
    unique_id { uniq_str }
    envelope FactoryGirl.build :envelope
  end
end

