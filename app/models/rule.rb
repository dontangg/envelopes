class Rule
  include Mongoid::Document

  embedded_in :user
  belongs_to :envelope

  field :search_text,       type: String
  field :replacement_text,  type: String
  field :order,             type: Integer

  default_scope order_by([[:order, :asc]])

  validates_presence_of :search_text

  def identify
  end

  def run(payee)
    if payee && payee.downcase.include?(self.search_text.downcase)
      payee = self.replacement_text if self.replacement_text.present?
      envelope_id = self.envelope_id unless self.envelope_id.nil?
      [payee, envelope_id]
    end
  end

end
