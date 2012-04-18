class Expense

  def amount
    @amount ||= 0.to_d
  end

  def amount=(new_amount)
    @amount = new_amount.to_d.abs
  end

  # Can be either :yearly or :monthly
  def frequency
    @frequency ||= :monthly
  end

  def frequency=(new_frequency)
    @frequency = new_frequency.to_sym
  end

  def occurs_on_day
    @occurs_on_day
  end

  def occurs_on_day=(new_day)
    new_day = new_day.to_i
    @occurs_on_day = new_day.blank? || new_day == 0 ? nil : new_day
  end

  def occurs_on_month
    @occurs_on_month
  end

  def occurs_on_month=(new_month)
    new_month = new_month.to_i
    @occurs_on_month = new_month.blank? || new_month == 0 ? nil : new_month
  end


  def initialize(attributes = nil)
    update_attributes(attributes)
  end

  def update_attributes(attributes)
    if attributes.respond_to?(:each_pair)
      attributes.each_pair do |attr_name, attr_value|
        send("#{attr_name}=", attr_value)
      end
    end
  end
end
