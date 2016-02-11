class TransferRule < ActiveRecord::Base

  scope :owned_by, ->(user_id) { where(user_id: user_id) }

  validates_presence_of :search_terms, :user_id, :percentage
  validates :percentage, numericality: { greater_than: 0, less_than: 100 }

  belongs_to :user
  belongs_to :envelope

  class << self
    def run_all(rules, transactions)

      transfer_cache = Hash.new(0)

      transactions.each do |txn|
        next if txn.amount <= 0

        rules.each do |rule|
          transfer_cache[rule] += txn.amount if rule.match?(txn.payee)
        end
      end

      transfers = transfer_cache.map do |rule, total|
        amount = (total * rule.percentage / 100).ceil(2)
        { payee: rule.payee, envelope_id: rule.envelope_id, amount: amount }
      end

    end
  end

  def split_terms
    @split_terms ||= read_attribute(:search_terms).split(",").map { |t| t.downcase.strip }
  end
  
  def match?(payee)
    downcase_payee = payee.downcase
    self.split_terms.any? do |term|
      payee && downcase_payee.include?(term)
    end
  end

end
