class Expense
  include Mongoid::Document

  embedded_in :envelope

  field :name,            type: String
  field :amount,          type: Float,  default: 0.0
  field :frequency,       type: Symbol, default: :monthly
  field :occurs_on_day,   type: Integer
  field :occurs_on_month, type: Integer

  # Don't put an object ID on expenses
  def identify
  end

  def occurs_on_day=(new_day)
    write_attribute(:occurs_on_day, new_day.blank? || new_day.to_i == 0 ? nil : new_day.to_i)
  end

  def occurs_on_month=(new_month)
    write_attribute(:occurs_on_month, new_month.blank? || new_month.to_i == 0 ? nil : new_month.to_i)
  end

end
