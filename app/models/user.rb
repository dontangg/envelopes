class User
  attr_accessible :email, :password, :password_confirmation, :bank_id, :bank_username, :bank_password, :bank_secret_questions, :bank_account_id
  has_secure_password
  validates_presence_of :password, :on => :create
  validates_presence_of :email
  validates_uniqueness_of :email, :on => :create

  has_many :rules
  
  serialize :bank_secret_questions

  def email=(new_email)
    pass = self.bank_password
    super
    self.bank_password = pass
  end
 
  def bank_password
    unless self.bank_password_cipher.blank?
      cipher = Gibberish::AES.new(self.email + 's')
      cipher.dec(self.bank_password_cipher)
    end
  end
  
  def bank_password=(unencrypted_password)
    unless unencrypted_password.blank?
      cipher = Gibberish::AES.new(self.email + 's')
      self.bank_password_cipher = cipher.enc(unencrypted_password)
    end
  end
end
