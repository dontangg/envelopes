class Rule < ActiveRecord::Base
  default_scope order(arel_table[:order])
  scope :owned_by, lambda { |user_id| where(user_id: user_id) }

  validates_presence_of :search_text, :user_id

  belongs_to :user
  belongs_to :envelope

end
