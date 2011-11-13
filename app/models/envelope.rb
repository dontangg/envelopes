class Envelope < ActiveRecord::Base
  scope :owned_by, lambda { |user_id| where(:user_id => user_id) }
  scope :income, where(income: true)
  scope :unassigned, where(unassigned: true)
  scope :generic, where(income: false, unassigned: false)
  
  belongs_to :user
  belongs_to :parent_envelope, class_name: 'Envelope', foreign_key: 'parent_envelope_id'
  has_many :child_envelopes, class_name: 'Envelope', foreign_key: 'parent_envelope_id'
  
  # This overrides the default to_param method that just returns id
  # This causes our find method to still work because find calls to_i() on it which will just return the id
  def to_param
    "#{id}-#{name.parameterize}" if id
  end
end
