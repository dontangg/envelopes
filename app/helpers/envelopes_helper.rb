module EnvelopesHelper
  def stringify_expense_frequency(expense)
    str = ""

    if expense.frequency == :monthly
      if expense.occurs_on && expense.occurs_on[:day]
        day = expense.occurs_on[:day] >= 28 ? "last" : expense.occurs_on[:day].ordinalize
        str += "on the #{day} day of "
      end
      str += "every month"
    else
      if expense.occurs_on && expense.occurs_on[:day] && expense.occurs_on[:month]
        str += "on #{Date::MONTHNAMES[expense.occurs_on[:month]]} #{expense.occurs_on[:day].ordinalize} "
      end
      str += "every year"
    end
  end
end
