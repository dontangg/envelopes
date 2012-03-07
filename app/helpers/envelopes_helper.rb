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

  def content_for_frequency_popover(expense)
    text_field_tag(:frequency, expense.frequency).to_str
    # "<input value=\"#{expense.frequency}\" />"
  end
end
