
FactoryGirl.define do
  factory :envelope do
    user { FactoryGirl.build(:user) }

    factory :income_envelope do
      name 'Available Cash'
      income true
    end

    factory :unassigned_envelope do
      name 'Unassigned'
      unassigned true
    end
  end
end

