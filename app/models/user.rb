class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::SecurePassword

  # Define the fields
  field :email,           type: String
  field :password_digest, type: String

  # Define embeds
  embeds_one  :bank

  # Mass asignment protection
  attr_accessible :email, :password, :password_confirmation

  has_secure_password

  validates_presence_of :password, :on => :create
  validates_presence_of :email
  validates_uniqueness_of :email, :on => :create

  ##has_many :rules

  class << self
    def find_by_email(email)
      self.first(conditions: {email: email})
    end
  end

  def email=(new_email)
    # Since the email is used while encrypting/decrypting the bank password,
    # we need to make sure we update the encrypted value if the email changes
    pass = self.bank.password if self.bank
    super
    self.bank.password = pass if self.bank
  end

end
