class TransactionImporter

  class << self

    def auto_import(user_id)
      user = User.find(user_id)

      return unless user.bank_username && user.bank_id

      # TODO: Fix Syrup... clients shouldn't have to know the time zone of the bank
      today = Time.now.in_time_zone('Mountain Time (US & Canada)').to_date
      starting_at = user.imported_transactions_at.nil? ? today - 1.month : user.imported_transactions_at - 1.week
      ending_at = today

      income_envelope_id = Envelope.owned_by(user.id).find_by(income: true).id
      unassigned_envelope_id = Envelope.owned_by(user.id).find_by(unassigned: true).id
      pending_envelope_id = Envelope.owned_by(user.id).find_by(pending: true).id

      # Delete all pending transactions
      Transaction.owned_by(user.id).where(pending: true).delete_all

      bank = Syrup.setup_institution(user.bank_id) do |config|
        config.username = user.bank_username
        config.password = user.bank_password
        config.secret_questions = user.bank_secret_questions
      end

      import_count = 0
      id_cache = {}
      account = bank.find_account_by_id user.bank_account_id
      account.find_transactions(starting_at, ending_at).each do |raw_transaction|

        transaction = Transaction.new payee: raw_transaction.payee,
                                      amount: raw_transaction.amount,
                                      posted_at: raw_transaction.posted_at,
                                      pending: raw_transaction.status == :pending

        if transaction.pending?
          transaction.envelope_id = pending_envelope_id
        else
          # Default to Available Cash envelope if the amount is not negative, Unassigned if it is negative
          transaction.envelope_id = transaction.amount < 0 ? unassigned_envelope_id : income_envelope_id
        end

        # Find a truly unique id for this transaction
        uniq_str = transaction.uniq_str
        num = 0
        num = num.next while id_cache[uniq_str + num.to_s]

        transaction.unique_id = uniq_str + num.to_s
        id_cache[transaction.unique_id] = true

        import_count = import_count.next if import(transaction, user.rules)
      end

      # Make sure that our balance matches the bank's balance
      account_balance = account.available_balance #account.prior_day_balance || account.current_balance
      my_current_balance = Transaction.owned_by(user.id).sum(:amount)
      if account_balance != my_current_balance
        amount = account_balance - my_current_balance
        Transaction.create  payee: "Bank account balance synchronization",
                            original_payee: "Bank account balance synchronization",
                            amount: amount,
                            posted_at: Date.today,
                            envelope_id: Envelope.owned_by(user.id).income.select(:id).first.id
      end

      user.imported_transactions_at = DateTime.now
      user.save

      import_count
    end

    def import(transaction, rules = [])
      # If the transaction is pending, don't worry about cleaning the name or assigning a unique id to it
      # because we just clear out all pending transactions before every import
      if transaction.pending?
        transaction.original_payee = transaction.payee
      else
        # Check for existence of this transaction
        # If the importing transaction has a unique_id and one already exists with the same unique_id,
        # it has already been imported.
        return nil if transaction.unique_id && Transaction.exists?(unique_id: transaction.unique_id)

        transaction.original_payee = transaction.payee.dup

        # Run any special rules for renaming transactions or moving them into envelopes
        Rule.run_all(rules, transaction)

        if transaction.payee == transaction.original_payee
          # Clean the payee
          strings_to_remove = [/[A-Z0-9]{17}\s*/, /P\.O\.S\.\s*PURCHASE\s*/i, /REF # \d{15}\s*/, /\b\d{3}-?\d{3}-?\d{4}\s+/, /\s#[^\s]+/, /\d{5,}/]
          strings_to_remove.each { |str| transaction.payee.gsub! str, '' }

          # Correct the case of the payee
          transaction.payee = transaction.payee.squish.titleize
        end
      end

      transaction.save
    end

  end

end
