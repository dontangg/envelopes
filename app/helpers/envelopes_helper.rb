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
    radio_button_tag(:frequency, :monthly, expense.frequency == :monthly).to_str +
    label_tag(:frequency_monthly, "Monthly").to_str +
    radio_button_tag(:frequency, :yearly, expense.frequency == :yearly).to_str +
    label_tag(:frequency_yearly, "Yearly").to_str +
    text_field_tag(:occurs_on_day, expense.occurs_on_day, type: 'text', placeholder: 'Day').to_str +
    text_field_tag(:occurs_on_month, expense.occurs_on_month, type: 'text', placeholder: 'Month').to_str +
    button_tag("Close", class: 'primary').to_str
  end
end
