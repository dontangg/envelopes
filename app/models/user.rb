class User < ActiveRecord::Base
  attr_accessible :email, :password, :password_confirmation, :bank_id, :bank_password, :bank_secret_questions
  has_secure_password
  validates_presence_of :password, :on => :create
  validates_presence_of :email
  validates_uniqueness_of :email, :on => :create
  
  serialize :bank_secret_questions
  
  def bank_password
    unless self.bank_password_cipher.blank?
      cipher = Gibberish::AES.new(self.password_digest + 's')
      cipher.dec(self.bank_password_cipher)
    end
  end
  
  def bank_password=(unencrypted_password)
    unless unencrypted_password.blank?
      cipher = Gibberish::AES.new(self.password_digest + 's')
      self.bank_password_cipher = cipher.enc(unencrypted_password)
    end
  end
end
