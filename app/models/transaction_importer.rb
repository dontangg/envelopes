class TransactionImporter

  class << self

    def self.auto_import(user_id)
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

end
