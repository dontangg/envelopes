class Expense

  def amount
    @amount ||= 0.0
  end
  
  def amount=(new_amount)
    @amount = new_amount.to_d
  end

  # Can be either :yearly or :monthly
  def frequency
    @frequency ||= :monthly
  end

  def frequency=(new_frequency)
    @frequency = new_frequency.to_sym
  end

  def occurs_on_day
    @occurs_on_day.blank? || @occurs_on_day == 0 ? nil : @occurs_on_day
  end

  def occurs_on_month
    @occurs_on_month.blank? || @occurs_on_month == 0 ? nil : @occurs_on_month
  end

  def occurs_on_day=(new_day)
    @occurs_on_day = new_day.blank? || new_day.to_i == 0 ? nil : new_day.to_i
  end

  def occurs_on_month=(new_month)
    @occurs_on_month = new_month.blank? || new_month.to_i == 0 ? nil : new_month.to_i
  end


  def initialize(attributes = nil)
    if attributes.respond_to?(:each_pair)
      attributes.each_pair do |attr_name, attr_value|
        send("#{attr_name}=", attr_value)
      end
    end
  end
  
  def update_attributes(attributes)
    attributes.each_pair do |attr_name, attr_value|
      send("#{attr_name}=", attr_value)
    end
  end
end
