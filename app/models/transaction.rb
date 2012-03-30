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
  
  def self.payee_suggestions_for_user_id(user_id, term, original = nil)
    unscoped do
      column = original ? arel_table[:original_payee] : arel_table[:payee]

      relation = owned_by(user_id)
        .where(column.matches("%#{term}%"))
        .select(column)
        .order(column)
        .order(arel_table[:posted_at].desc)
      
      relation = relation.where(arel_table[:payee].not_eq(arel_table[:original_payee])) unless original

      relation.map(&column.name)
    end
  end
  
  def self.create_transfer(amount, from_envelope_id, to_envelope_id, from_txn_payee, to_txn_payee)
    from_txn = Transaction.create posted_at: Date.today, payee: from_txn_payee, original_payee: from_txn_payee, envelope_id: from_envelope_id, amount: -amount
    to_txn = Transaction.create posted_at: Date.today, payee: to_txn_payee, original_payee: to_txn_payee, envelope_id: to_envelope_id, amount: amount, associated_transaction_id: from_txn.id

    from_txn.associated_transaction_id = to_txn.id
    from_txn.save
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

  def self.import_all(user_id)
    user = User.find(user_id)

    return unless user.bank_username && user.bank_id

    starting_at = user.imported_transactions_at.nil? ? Date.today - 1.month : user.imported_transactions_at - 1.week
    
    income_envelope_id = Envelope.owned_by(user.id).find_by_income(true).id
    unassigned_envelope_id = Envelope.owned_by(user.id).find_by_unassigned(true).id
    
    bank = Syrup.setup_institution(user.bank_id) do |config|
      config.username = user.bank_username
      config.password = user.bank_password
      config.secret_questions = user.bank_secret_questions
    end
    
    import_count = 0
    id_cache = {}
    account = bank.find_account_by_id user.bank_account_id
    account.find_transactions(starting_at, Date.today).each do |raw_transaction|
      next if raw_transaction.status == :pending
      
      transaction = Transaction.new payee: raw_transaction.payee,
                                    amount: raw_transaction.amount,
                                    posted_at: raw_transaction.posted_at,
                                    pending: raw_transaction.status == :pending

      # Default to Available Cash if the amount is not negative, Unassigned if it is negative
      transaction.envelope_id = transaction.amount < 0 ? unassigned_envelope_id : income_envelope_id 
      
      # Find a truly unique id for this transaction
      uniq_str = transaction.uniq_str
      num = 0
      num = num.next while id_cache[uniq_str + num.to_s]
      
      transaction.unique_id = uniq_str + num.to_s
      id_cache[transaction.unique_id] = true
      
      import_count = import_count.next if import(transaction, user.rules)
    end
    
    # Make sure that our balance matches the bank's balance
    account_balance = account.prior_day_balance || account.current_balance
    my_current_balance = Transaction.owned_by(user.id).sum(:amount)
    if account_balance != my_current_balance
      amount = account_balance - my_current_balance
      Transaction.create  payee: "Bank account balance synchronization",
                          original_payee: "Bank account balance synchronization",
                          amount: amount,
                          posted_at: Date.today,
                          envelope_id: Envelope.owned_by(user.id).where(income: true).select(:id).first.id
    end

    user.imported_transactions_at = DateTime.now
    user.save
    
    import_count
  end

  def self.import(transaction, rules = [])
    # Check for existence of this transaction
    # If the importing transaction has a unique_id and one already exists with the same unique_id,
    # it has already been imported.
    return nil if transaction.unique_id && Transaction.exists?(unique_id: transaction.unique_id)
    
    transaction.original_payee = transaction.payee.dup

    # Run any special rules for renaming transactions or moving them into envelopes
    rules.each do |rule|
      rule_result = rule.run(transaction.payee)
      if rule_result
        transaction.payee = rule_result[0] if rule_result[0]
        transaction.envelope_id = rule_result[1] if rule_result[1]
      end
    end

    if transaction.payee == transaction.original_payee
      # Clean the payee
      strings_to_remove = [/[A-Z0-9]{17}/, /P\.O\.S\.\s*PURCHASE/i, /REF # \d{15}/, /\d{3}-?\d{3}-?\d{4}/, /\s#[^\s]+/]
      strings_to_remove.each { |str| transaction.payee.gsub! str, '' }

      # Correct the case of the payee
      transaction.payee = transaction.payee.strip.titleize
    end
    
    transaction.save
  end

end
