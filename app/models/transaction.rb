class Transaction < ActiveRecord::Base
  default_scope order(arel_table[:posted_at].desc)
  scope :starting_at, lambda {|start_date| where(arel_table[:posted_at].gteq(start_date)) }
  scope :ending_at, lambda {|end_date| where(arel_table[:posted_at].lteq(end_date)) }
  scope :without_transfers, where(arel_table[:unique_id].not_eq(nil))
  
  validates_presence_of :posted_at, :payee, :original_payee, :amount, :envelope_id
  validates_uniqueness_of :unique_id, :allow_nil => true
  
  before_save :strip_payee
  after_save :check_associated_transaction
  
  belongs_to :envelope
  belongs_to :associated_transaction, class_name: 'Transaction', foreign_key: 'associated_transaction_id'
  
  def self.owned_by(user_id)
    user_id = user_id.id if user_id.respond_to? :id
    envelopes_table = Envelope.arel_table
    where(self.arel_table[:envelope_id].in(envelopes_table.project(envelopes_table[:id]).where(envelopes_table[:user_id].eq(user_id))))
  end
  
  def self.payee_suggestions_for_user_id(user_id, term)
    unscoped do
      owned_by(user_id)
        .where(arel_table[:payee].not_eq(arel_table[:original_payee]).and(arel_table[:payee].matches("%#{term}%")))
        .select(arel_table[:payee])
        .order(arel_table[:payee])
        .order(arel_table[:posted_at].desc)
    end
  end
  
  def strip_payee
    payee.strip!
  end
  
  def check_associated_transaction
    if @amount_changed && self.associated_transaction_id.present?
      if associated_transaction.amount != -self.amount
        associated_transaction.update_column(:amount, -self.amount)
      end
    end
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
  
  def amount=(new_amount)
    if self.amount != new_amount
      write_attribute(:amount, new_amount)
      @amount_changed = true
    end
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
