
FactoryGirl.define do
  factory :transaction do
    transaction_group { FactoryGirl.build(:transaction_group) }
    payee "Walmart"
    original_payee "12345678 P.O.S WALMART 1234 OREM UT"
    posted_at Date.today
    amount 13.24
    unique_count 1

    factory :transaction_transfer do
      payee "Envelope transfer from ... to ..."
      original_payee "Envelope transfer from ... to ..."
      unique_count nil
    end
  end
end

