class Envelope
  include Mongoid::Document
  
  embedded_in :user
  embeds_one  :expense

  field :name,                type: String
  field :income,              type: Boolean
  field :unassigned,          type: Boolean
  field :parent_envelope_id,  type: BSON::ObjectId

  default_scope order_by([[:name, :asc]])
  scope :income, where(income: true)
  scope :unassigned, where(unassigned: true)
  scope :generic, where(income: false, unassigned: false)

  ##has_many :transactions

  ##after_create :move_parents_transactions
  ##before_destroy :check_for_transactions
  
  class << self
    #def income
    #  self.first(conditions: {income: true}) #where(income: true)
    #end
  end

  # This overrides the default to_param method that just returns id
  def to_param
    name.parameterize if id # I think that this needs to return nil if this envelope hasn't been saved
  end

  def parent_envelope_id=(new_id)
    super
    @parent_envelope = nil
  end

  def parent_envelope
    if self.parent_envelope_id
      @parent_envelope ||= self.user.envelopes.select { |envelope| envelope.id == self.parent_envelope_id }.first
    else
      nil
    end
  end

  def parent_envelope=(new_parent_envelope)
    @parent_envelope = nil
    self.parent_envelope_id = new_parent_envelope.id
  end

  def child_envelopes
    @child_envelopes ||= self.user.envelopes.select { |envelope| self.id == envelope.parent_envelope_id }
  end

  def self_and_child_envelope_ids
    child_ids = [self.id]

    child_envelopes.each do |child|
      child_ids.concat child.self_and_child_envelope_ids
    end

    child_ids
  end

  def transactions(start_date, end_date = Date.today)
    start_year_month = start_date.strftime("%Y-%m")
    end_year_month = end_date.strftime("%Y-%m")
    groups = TransactionGroup.where(:year_month.gte => start_year_month)
                             .and(:year_month.lte => end_year_month)
                             .and(:envelope_id.in => self_and_child_envelope_ids)
                             .desc(:year_month)
    transactions = []
    groups.each do |group|
      group.transactions.each do |txn|
        transactions << txn if txn.posted_at >= start_date && txn.posted_at <= end_date
      end
    end

    # Sort by posted_at, then payee, then unique_count
    transactions.sort! do |a, b|
      result = b.posted_at <=> a.posted_at
      if result == 0
        result = a.payee <=> b.payee
        if result == 0
          result = a.unique_count <=> b.unique_count
        end
      end

      result
    end

    transactions
  end

  def total_amount
    unless @total_amount
      # Add up all child envelopes transactions
      @total_amount = child_envelopes.inject(0) { |running_total, child_envelope| running_total + (child_envelope.total_amount || 0) }

      # Add up all my transactions
      groups = TransactionGroup.where(envelope_id: self.id).only(:total_amount)
      @total_amount = groups.inject(@total_amount) { |running_total, group| running_total + (group.total_amount || 0) }
    end
    @total_amount
  end


  ###############


  attr_accessor :suggested_amount

  def move_parents_transactions
    if self.parent_envelope_id.present?
      Envelope.move_transactions(self.parent_envelope_id, self.id)
    end
  end

  def self.move_transactions(from_envelope_id, to_envelope_id)
    Transaction.where(envelope_id: from_envelope_id).update_all(envelope_id: to_envelope_id)
  end

  def check_for_transactions
    self.transactions.count == 0
  end

  def expense=(new_expense)
    if new_expense.is_a?(Hash)
      if self.expense
        self.expense.update_attributes(new_expense)
      else
        self.expense = Expense.new(new_expense)
      end
    else
      super
    end
  end

  #def total_amount=(new_amount)
  #  @total_amount = new_amount
  #end

  def inclusive_total_amount(organized_envelopes = nil)
    children = organized_envelopes.nil? ? self.child_envelopes : organized_envelopes[id]
    children.inject(total_amount) {|sum, envelope| sum + envelope.inclusive_total_amount(organized_envelopes) }
  end

  def full_name(all_envelopes = nil)
    return @full_name if @full_name

    name = if parent_envelope_id.nil?
      self.name
    else
      parent_full_name = self.parent_envelope.full_name(all_envelopes)

      "#{parent_full_name}: #{self.name}"
    end

    @full_name = name
  end

  def simple_monthly_budget
    if self.expense
      if self.expense.frequency == :monthly
        self.expense.amount
      else
        self.expense.amount / 12
      end
    else
      0
    end
  end
  
  def amount_funded_this_month
    @amount_funded_this_month ||= amount_funded_between(Date.today.beginning_of_month, Date.today.end_of_month)
  end
  
  # This method is just to be able to populate 
  def amount_funded_this_month=(amount)
    @amount_funded_this_month = amount
  end

  def amount_funded_between(start_date = Date.today.beginning_of_month, end_date = Date.today.end_of_month)
    where_clause = Transaction.arel_table[:amount].gt(0)
      .and(Transaction.arel_table[:posted_at].gteq(start_date))
      .and(Transaction.arel_table[:posted_at].lteq(end_date))
    all_transactions.where(where_clause).sum(:amount)
  end

  def amount_spent_this_month
    amount_spent_between(Date.today.beginning_of_month, Date.today.end_of_month)
  end

  def amount_spent_between(start_date = Date.today.beginning_of_month, end_date = Date.today.end_of_month)
    transaction_table = Transaction.arel_table
    where_clause = transaction_table[:amount].lt(0)
      .and(transaction_table[:posted_at].gteq(start_date))
      .and(transaction_table[:posted_at].lteq(end_date))
    all_transactions.where(where_clause).sum(:amount)
  end
  
  # A chainable scope that also returns the amount in the envelope
  def self.with_amounts
    et = Envelope.arel_table
    tt = Transaction.arel_table
    
    envelopes_columns = Envelope.column_names.map {|column_name| et[column_name.to_sym] }
    
    sum_function = Arel::Nodes::NamedFunction.new('SUM', [tt[:amount]])
    aggregation = Arel::Nodes::NamedFunction.new('COALESCE', [sum_function, 0], 'total_amount')
    
    select([et[Arel.star], aggregation])
      .joins(Arel::Nodes::OuterJoin.new(tt, Arel::Nodes::On.new(et[:id].eq(tt[:envelope_id]))))
      .group(envelopes_columns)
  end
  
  def self.add_funded_this_month(envelopes, user_id)
    et = Envelope.arel_table
    tt = Transaction.arel_table
    
    envelopes_columns = Envelope.column_names.map {|column_name| et[column_name.to_sym] }
    
    sum_function = Arel::Nodes::NamedFunction.new('SUM', [tt[:amount]])
    aggregation = Arel::Nodes::NamedFunction.new('COALESCE', [sum_function, 0], 'total_amount')
    
    envelopes2 = select([et[:id], aggregation])
      .joins(Arel::Nodes::OuterJoin.new(tt, Arel::Nodes::On.new(et[:id].eq(tt[:envelope_id]))))
      .where(tt[:amount].gt(0).and(tt[:posted_at].gteq(Date.today.beginning_of_month)).and(et[:user_id].eq(user_id)))
      .group([et[:id]])
    
    envelopes.each do |env|
      env2 = envelopes2.select {|envelope| envelope.id == env.id}.first
      env.amount_funded_this_month = env2.nil? ? 0 : env2.total_amount
    end
  end

  def self.all_envelope(total_amount = nil)
    env = Envelope.new(name: 'All Transactions')
    env.total_amount = total_amount if total_amount
    env.id = 0
    env
  end
  
  # Returns a Hash with all the envelopes organized. eg:
  #
  #   'sys' => [array of income and unassigned envelopes]
  #   nil   => [array of all envelopes with parent_envelope_id = nil]
  #   1     => [array of envelopes with parent_envelope_id = 1]
  def self.organize(all_envelopes)
    total_amount = 0
    envelopes = Hash.new { |hash, key| hash[key] = [] }
    all_envelopes.each do |envelope|
      total_amount += envelope.total_amount
      envelope.full_name(all_envelopes) # Have each envelope figure out and memoize its full_name
      if envelope.income || envelope.unassigned
        envelopes['sys'] << envelope
      else
        envelopes[envelope.parent_envelope_id] << envelope
      end
    end
    
    envelopes['sys'].unshift(all_envelope(total_amount))
    
    all_envelopes.sort! {|e1, e2| e1.full_name <=> e2.full_name }

    envelopes
  end

  # TODO: Create a class out of this method: SuggestionCalculator
  def self.calculate_suggestions(organized_envelopes, current_envelope = nil)
    if current_envelope.nil?
      organized_envelopes[nil].each {|envelope| calculate_suggestions(organized_envelopes, envelope) }
    else
      
      # See if this envelope contains other envelopes
      if organized_envelopes[current_envelope.id].blank?
        if current_envelope.expense.nil?
          current_envelope.suggested_amount = 0
        else
          if current_envelope.expense.frequency == :monthly
            # If it is a monthly envelope, suggest the full amount
            current_envelope.suggested_amount = current_envelope.expense.amount
          else
            if current_envelope.expense.occurs_on_day.nil? || current_envelope.expense.occurs_on_month.nil?
              # If it is a yearly envelope without a date, suggest the full amount / 12
              current_envelope.suggested_amount = current_envelope.expense.amount / 12
            else
              # If it is a yearly envelope with a date, complicate :)
              if current_envelope.suggested_amount.nil?
                # Get all the envelopes with the same parent that are also yearly with a date
                yearlies = []
                organized_envelopes[current_envelope.parent_envelope_id].each do |envelope|
                  if envelope.expense.try(:frequency) == :yearly && envelope.expense.occurs_on_day.present? && envelope.expense.occurs_on_month.present?
                    months = envelope.expense.occurs_on_month
                    months += 12 if envelope.expense.occurs_on_month < Date.today.month
                    months -= Date.today.month - 1
                    yearlies << {
                      sort_by_key: "%02d%02d" % [months, envelope.expense.occurs_on_day],
                      number_of_months_before_due: months,
                      envelope: envelope
                    }
                  end
                end

                # Order the envelopes by which is due next
                yearlies = yearlies.sort {|a, b| a[:sort_by_key] <=> b[:sort_by_key] }

                # Figure out how much to distribute between all these envelopes
                # For each envelope:
                # * Add up all the envelope amounts up to the current envelope
                # * Divide by the number of months left and take this number if is the highest so far
                total_amount = 0
                max_monthly = 0
                yearlies.each do |yearly|
                  total_amount += yearly[:envelope].expense.amount - yearly[:envelope].total_amount + yearly[:envelope].amount_funded_this_month
                  max_monthly = [max_monthly, total_amount / yearly[:number_of_months_before_due]].max
                end

                # Take that amount and suggest it for the first envelope due
                # Take any extra and suggest it for the next envelope, etc.
                monthly_amount_left = max_monthly
                yearlies.each do |yearly|
                  amount_left = [yearly[:envelope].expense.amount - yearly[:envelope].total_amount, 0].max
                  suggested_amount = [amount_left, monthly_amount_left].min
                  
                  monthly_amount_left -= suggested_amount
                  yearly[:envelope].suggested_amount = suggested_amount
                end
                
              end
            end
          end
        end
      else
        # If the envelope has other envelopes, it can't have an expense, so its suggestion is the sum of its children's suggestions
        current_envelope.suggested_amount = organized_envelopes[current_envelope.id].inject(0) do |sum, child_envelope|
          sum + (calculate_suggestions(organized_envelopes, child_envelope) || 0)
        end
      end

      current_envelope.suggested_amount
    end
  end
end
