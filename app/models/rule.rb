class Rule < ActiveRecord::Base
  attr_accessible :search_text, :replacement_text, :envelope_id, :order, :user_id, :envelope, :user

  default_scope order(arel_table[:order])
  scope :owned_by, lambda { |user_id| where(user_id: user_id) }

  validates_presence_of :search_text, :user_id

  belongs_to :user
  belongs_to :envelope

  class << self
    def run_all(rules, transaction)
      rules.each do |rule|
        rule_result = rule.run(transaction.original_payee)
        if rule_result
          transaction.payee = rule_result[0] if rule_result[0]
          transaction.envelope_id = rule_result[1] if rule_result[1]
          break
        end
      end
    end
  end

  def run(payee)
    if payee && payee.downcase.include?(self.search_text.downcase)
      new_payee = self.replacement_text if self.replacement_text.present?
      [new_payee, self.envelope_id]
    end
  end

end
