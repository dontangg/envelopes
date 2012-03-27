
FactoryGirl.define do
  factory :user do
    email 'jim@example.com'
    password_digest BCrypt::Password.create('jimpass')
  end
end

##someone:
##  email: someone@example.com
##  password_digest: <%= BCrypt::Password.create('a pass') %>
