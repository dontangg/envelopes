module EnvelopesHelper
  def stringify_expense_frequency(expense)
    str = ""

    if expense.frequency == :monthly
      if expense.occurs_on_day
        day = expense.occurs_on_day >= 28 ? "last" : expense.occurs_on_day.ordinalize
        str += "on the #{day} day of "
      end
      str += "every month"
    else
      if expense.occurs_on_day && expense.occurs_on_month
        str += "on #{Date::MONTHNAMES[expense.occurs_on_month]} #{expense.occurs_on_day.ordinalize} "
      end
      str += "every year"
    end
  end
end
