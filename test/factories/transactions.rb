
FactoryGirl.define do
  factory :transaction do
    posted_at Date.today
    payee 'Best Buy'
    original_payee '1239465 BEST BUY USA'
    amount 1.23
    pending false
    unique_id '2012-04-02~1239465 BEST BUY USA~1.23~false~'
    envelope FactoryGirl.build :envelope
  end
end

