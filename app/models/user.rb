class User < ActiveRecord::Base
  has_secure_password
  #validates_presence_of :password, :on => :create
  validates_presence_of :email
  validates_uniqueness_of :email, :on => :create

  has_many :rules
  has_many :envelopes

  serialize :bank_secret_questions

  def email=(new_email)
    pass = self.bank_password
    super
    self.bank_password = pass
  end

  def bank_password
    unless self.bank_password_cipher.blank?
      cipher = Gibberish::AES::CBC.new(self.email + 's')
      cipher.decrypt(self.bank_password_cipher)
    end
  end

  def bank_password=(unencrypted_password)
    unless unencrypted_password.blank?
      cipher = Gibberish::AES::CBC.new(self.email + 's')
      self.bank_password_cipher = cipher.encrypt(unencrypted_password)
    end
  end

  def generate_api_token
    self.api_token = rand(3656158440062976).to_s(36).rjust(10, '0')
    save
  end
end
