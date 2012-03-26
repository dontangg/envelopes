
FactoryGirl.define do
  factory :transaction_group do
    user { FactoryGirl.build(:user) }
    envelope { FactoryGirl.build(:envelope, user: user) }
    year_month Date.today.strftime("%Y-%m")

    factory :transaction_group_with_transactions do
      transactions do
        [
          FactoryGirl.build(:transaction_transfer),
          FactoryGirl.build(:transaction)
        ]
      end
    end
  end
end

