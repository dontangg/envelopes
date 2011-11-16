class Transaction < ActiveRecord::Base
  scope :recent, where("posted_at >= ?", Date.today - 1.month)
  default_scope :order => 'posted_at DESC'
  
  validates_presence_of :posted_at, :payee, :original_payee, :amount
  validates_uniqueness_of :unique_id, :allow_nil => true
  validate :one_envelope_id_must_be_present
  
  before_save :strip_payee
  
  belongs_to :to_envelope, :class_name => "Envelope"
  belongs_to :from_envelope, :class_name => "Envelope"
  
  def one_envelope_id_must_be_present
    if from_envelope_id.blank? && to_envelope_id.blank?
      errors.add(:from_envelope_id, " or to_envelope_id must be present")
      errors.add(:to_envelope_id, " or from_envelope_id must be present")
    end
  end
  
  def self.owned_by(user_id)
    envelope_ids = Envelope.owned_by(user_id).select(:id).map(&:id)
    
    where(self.arel_table[:from_envelope_id].in(envelope_ids).or(self.arel_table[:to_envelope_id].in(envelope_ids)))
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
