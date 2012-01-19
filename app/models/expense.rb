class Expense
  attr_accessor :amount

  # Can be either :yearly or :monthly
  attr_accessor :frequency

  # This can be just a 5 if the frequency is monthly meaning that the expense
  # occurs on the 5th every month
  #
  # This can be a Hash { day: 5, month: 12 } if the frequency is yearly meaning
  # that the expense occurs December 5th, every year
  attr_accessor :occurs_on
end