class Transaction < ActiveRecord::Base
  default_scope order(arel_table[:posted_at].desc)
  scope :recent, where(arel_table[:posted_at].gteq(Date.today - 1.month))
  
  validates_presence_of :posted_at, :payee, :original_payee, :amount, :envelope_id
  validates_uniqueness_of :unique_id, :allow_nil => true
  
  before_save :strip_payee
  
  belongs_to :envelope
  has_one :associated_transaction, class_name: 'Transaction', foreign_key: 'associated_transaction_id'
  
  def self.owned_by(user_id)
    envelopes_table = Envelope.arel_table
    where(self.arel_table[:envelope_id].in(envelopes_table.project(envelopes_table[:id]).where(envelopes_table[:user_id].eq(user_id))))
  end
  
  def strip_payee
    payee.strip!
  end
  
  def cleared?
    !pending?
  end
  
  def <=>(other)
    # Transactions are ordered by posted_at, payee, then amount
    result = self.posted_at <=> other.posted_at
    
    if result == 0
      result = self.original_payee <=> other.original_payee
      
      if result == 0
        result = self.amount <=> other.amount
      end
    end
    
    result
  end
  
  def uniq_str
    str = ''
    str += posted_at.strftime('%F') if posted_at.respond_to? :strftime
    str += '~'
    str += (original_payee || payee).strip.gsub(/\s+/, ' ')
    str += '~'
    str += amount.to_s unless amount.nil?
    str += '~'
    str += pending?.to_s
    str += '~'
    
    str
  end
end
