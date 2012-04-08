class Envelope < ActiveRecord::Base
  
  default_scope order(arel_table[:name])
  scope :owned_by, lambda { |user_id| where(user_id: user_id) }
  scope :income, where(income: true)
  scope :unassigned, where(unassigned: true)
  scope :generic, where(income: false, unassigned: false)

  belongs_to :user
  belongs_to :parent_envelope, class_name: 'Envelope', foreign_key: 'parent_envelope_id'
  has_many :child_envelopes, class_name: 'Envelope', foreign_key: 'parent_envelope_id'
  has_many :transactions

  after_create :move_parents_transactions
  before_destroy :check_for_any_transactions
  
  serialize :expense, Expense

  attr_accessor :suggested_amount

  class << self

    def move_transactions(from_envelope_id, to_envelope_id)
      Transaction.where(envelope_id: from_envelope_id).update_all(envelope_id: to_envelope_id)
    end

    # A chainable scope that also returns the amount in the envelope
    def with_amounts
      et = Envelope.arel_table
      tt = Transaction.arel_table
      
      envelopes_columns = Envelope.column_names.map {|column_name| et[column_name.to_sym] }
      
      sum_function = Arel::Nodes::NamedFunction.new('SUM', [tt[:amount]])
      aggregation = Arel::Nodes::NamedFunction.new('COALESCE', [sum_function, 0], 'total_amount')
      
      select([et[Arel.star], aggregation])
        .joins(Arel::Nodes::OuterJoin.new(tt, Arel::Nodes::On.new(et[:id].eq(tt[:envelope_id]))))
        .group(envelopes_columns)
    end
    
    def add_funded_this_month(envelopes, user_id)
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

    def all_child_envelope_ids(envelope_id, organized_envelopes = nil)
      children = organized_envelopes ? organized_envelopes[envelope_id] : Envelope.where(parent_envelope_id: envelope_id)
      all_child_ids = children.map(&:id)
      children.each do |child|
        all_child_ids << all_child_envelope_ids(child.id, organized_envelopes)
      end
      all_child_ids.flatten
    end

    def all_envelope(total_amount = nil)
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
    def organize(all_envelopes)
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

  end

  def move_parents_transactions
    if self.parent_envelope_id.present?
      Envelope.move_transactions(self.parent_envelope_id, self.id)
    end
  end

  def check_for_any_transactions
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

  # This overrides the default to_param method that just returns id
  # This causes our find method to still work because find calls to_i() on it which will just return the id
  def to_param
    "#{id}-#{name.parameterize}" if id
  end
  
  def total_amount
    @total_amount ||= (read_attribute(:total_amount) || transactions.sum(:amount) || "0").to_d
  end
  
  def total_amount=(new_amount)
    @total_amount = new_amount.nil? ? nil : BigDecimal.new(new_amount.to_s)
  end

  def inclusive_total_amount(organized_envelopes = nil)
    children = organized_envelopes.nil? ? self.child_envelopes : organized_envelopes[id]
    children.inject(total_amount) {|sum, envelope| sum + envelope.inclusive_total_amount(organized_envelopes) }
  end

  def full_name(all_envelopes = nil)
    return @full_name if @full_name

    name = if parent_envelope_id.nil?
      self.name
    else
      parent_envelope = all_envelopes ? all_envelopes.select {|envelope| envelope.id == self.parent_envelope_id}.first : Envelope.find(self.parent_envelope_id)
    
      parent_full_name = parent_envelope.full_name(all_envelopes)

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
  
  def all_transactions(organized_envelopes = nil)
    if self.id == 0 && organized_envelopes.present? # All Transactions envelope
      all_child_envelope_ids = []
      organized_envelopes[nil].each do |envelope|
        all_child_envelope_ids.concat Envelope.all_child_envelope_ids(envelope.id, organized_envelopes)
      end
      all_child_envelope_ids.concat organized_envelopes['sys']
    else
      all_child_envelope_ids = Envelope.all_child_envelope_ids(self.id, organized_envelopes) << self.id
    end
    Transaction.where(envelope_id: all_child_envelope_ids)
  end
  
end
