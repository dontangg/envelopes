class Expense

  def amount
    @amount ||= 0.0
  end
  
  def amount=(new_amount)
    @amount = new_amount.to_f
  end

  # Can be either :yearly or :monthly
  def frequency
    @frequency ||= :monthly
  end

  def frequency=(new_frequency)
    @frequency = new_frequency.to_sym
  end

  attr_accessor :occurs_on_day, :occurs_on_month

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
