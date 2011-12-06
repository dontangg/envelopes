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
  
  # This overrides the default to_param method that just returns id
  # This causes our find method to still work because find calls to_i() on it which will just return the id
  def to_param
    "#{id}-#{name.parameterize}" if id
  end
  
  def total_amount
    @total_amount ||= read_attribute(:total_amount) || transactions.sum(:amount)
  end

  def inclusive_total_amount(organized_envelopes = nil)
    children = organized_envelopes.nil? ? self.child_envelopes : organized_envelopes[id]
    children.inject(total_amount) {|sum, envelope| sum + envelope.inclusive_total_amount(organized_envelopes) }
  end

  def full_name(all_envelopes = nil)
    get_envelope = lambda do |envelope_id|
      if envelope_id
        if all_envelopes
          all_envelopes.select {|envelope| envelope.id == envelope_id}.first
        else
          Envelope.find(envelope_id)
        end
      end
    end

    name = nil
    envelope = self
    while envelope
      name = ": #{name}" if name
      name = envelope.name + name.to_s
      envelope = get_envelope.call(envelope.parent_envelope_id)
    end

    name
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
  
  # Returns a Hash with all the envelopes organized. eg:
  #
  #   nil   => [array of all envelopes with parent_envelope_id = nil]
  #   1     => [array of envelopes with parent_envelope_id = 1]
  def self.organize(all_envelopes)
    envelopes = Hash.new { |hash, key| hash[key] = [] }
    all_envelopes.each do |envelope|
      envelopes[envelope.parent_envelope_id].push(envelope)
    end
    
    envelopes
  end
end
