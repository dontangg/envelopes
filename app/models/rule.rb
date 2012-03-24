class Rule
  default_scope order(arel_table[:order])
  scope :owned_by, lambda { |user_id| where(user_id: user_id) }

  validates_presence_of :search_text, :user_id

  belongs_to :user
  belongs_to :envelope

  def run(payee)
    if payee && payee.downcase.include?(self.search_text.downcase)
      payee = self.replacement_text if self.replacement_text.present?
      envelope_id = self.envelope_id unless self.envelope_id.nil?
      [payee, envelope_id]
    end
  end

end
