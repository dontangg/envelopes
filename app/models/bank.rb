class Bank
  include Mongoid::Document

  embedded_in :user
  embeds_many :secret_questions

  field :syrup_id,        type: String
  field :username,        type: String
  field :password_cipher, type: String
  field :account_id,      type: String
  field :imported_at,     type: DateTime

  # don't include a mongo id on this embedded document
  def identify
  end

  def password
    unless self.password_cipher.blank?
      cipher = Gibberish::AES.new(user.email + 's')
      cipher.dec(self.password_cipher)
    end
  end

  def password=(unencrypted_password)
    unless unencrypted_password.blank?
      cipher = Gibberish::AES.new(user.email + 's')
      self.password_cipher = cipher.enc(unencrypted_password)
    end
  end

end

class SecretQuestion
  include Mongoid::Document

  embedded_in :bank

  field :question,  type: String
  field :answer,    type: String

  def identify
  end
end
