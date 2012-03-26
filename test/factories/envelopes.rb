
FactoryGirl.define do
  factory :envelope do
    user { FactoryGirl.build(:user) }
    income false
    unassigned false

    factory :income_envelope do
      name 'Available Cash'
      income true
    end

    factory :unassigned_envelope do
      name 'Unassigned'
      unassigned true
    end

    factory :auto_envelope do
      name 'Auto'
    end
  end
end

