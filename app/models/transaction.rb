class Transaction < ActiveRecord::Base
  attr_accessible :posted_at, :payee, :original_payee, :amount, :envelope_id, :associated_transaction_id, :pending

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

  class << self

    def owned_by(user_id)
      user_id = user_id.id if user_id.respond_to? :id
      envelopes_table = Envelope.arel_table
      where(self.arel_table[:envelope_id].in(envelopes_table.project(envelopes_table[:id]).where(envelopes_table[:user_id].eq(user_id))))
    end

    def payee_suggestions_for_user_id(user_id, term, original = nil)
      unscoped do
        column = original ? arel_table[:original_payee] : arel_table[:payee]

        relation = owned_by(user_id)
          .where(column.matches("%#{term.gsub(/\s+/, '%')}%"))
          .select(column)
          .order(column)
          .order(arel_table[:posted_at].desc)

        relation = relation.where(arel_table[:payee].not_eq(arel_table[:original_payee])) unless original

        relation.map(&column.name)
      end
    end

    def create_transfer(amount, from_envelope_id, to_envelope_id, from_txn_payee, to_txn_payee)
      from_txn = Transaction.create posted_at: Date.today, payee: from_txn_payee, original_payee: from_txn_payee, envelope_id: from_envelope_id, amount: -amount
      to_txn = Transaction.create posted_at: Date.today, payee: to_txn_payee, original_payee: to_txn_payee, envelope_id: to_envelope_id, amount: amount, associated_transaction_id: from_txn.id

      from_txn.update_column :associated_transaction_id, to_txn.id

      from_txn
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

  def <=>(other)
    # Transactions are ordered by posted_at, original_payee, then amount
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
