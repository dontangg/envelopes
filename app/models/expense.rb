class Expense

  def amount
    @amount || 0
  end
  
  def amount=(new_amount)
    @amount = new_amount
  end

  # Can be either :yearly or :monthly
  attr_accessor :frequency

  # This can be just a 5 if the frequency is monthly meaning that the expense
  # occurs on the 5th every month
  #
  # This can be a Hash { day: 5, month: 12 } if the frequency is yearly meaning
  # that the expense occurs December 5th, every year
  attr_accessor :occurs_on

  def initialize(attributes = nil)
    if attributes.respond_to?(:each_pair)
      attributes.each do |attr_name, attr_value|
        instance_variable_set("@#{attr_name}", attr_value)
      end
    end
  end
end
