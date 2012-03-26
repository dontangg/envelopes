class TransactionGroup
  include Mongoid::Document

  belongs_to  :user
  belongs_to  :envelope
  embeds_many :transactions

  field :year_month,    type: String
  field :total_amount,  type: Float,  default: 0.0
  
  index([
    [:user_id, Mongo::ASCENDING],
    [:envelope_id, Mongo::ASCENDING],
    [:year_month, Mongo::DESCENDING]
  ])

  validates_presence_of :user_id, :envelope_id, :year_month, :total_amount
end

