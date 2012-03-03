module EnvelopesHelper
  def stringify_expense(expense)
    str = "#{number_to_currency(expense.amount)} on "

    if expense.frequency == :monthly
      str += expense.occurs_on[:day] == 31 ? "the last" : "the #{expense.occurs_on[:day].ordinalize}"
      str += " day of every month"
    else
      str += "#{Date::MONTHNAMES[expense.occurs_on[:month]]} #{expense.occurs_on[:day].ordinalize}"
      str += " every year"
    end
  end
end
