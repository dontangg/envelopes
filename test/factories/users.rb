require 'bcrypt'

FactoryGirl.define do
  factory :user do
    sequence(:email) { |n| "test#{n}@gmail.com" }
    password_digest BCrypt::Password.create('pass')

    initialize_with do
      user = User.new
      user.instance_variable_set :@password, 'pass'
      user
    end
  end
end

