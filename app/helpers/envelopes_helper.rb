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
        str += "on #{Date::MONTHNAMES[expense.occurs_on_month.to_i]} #{expense.occurs_on_day.to_i.ordinalize} "
      end
      str += "every year"
    end
  end

  def content_for_frequency_popover(envelope)
    form_for(envelope, remote: true) do |f|
      f.fields_for(:expense) do |f2|
        f2.radio_button(:frequency, :monthly, checked: envelope.expense.frequency == :monthly) +
        f2.label(:frequency_monthly, "Monthly") +
        f2.radio_button(:frequency, :yearly, checked: envelope.expense.frequency == :yearly) +
        f2.label(:frequency_yearly, "Yearly") +
        f2.text_field(:occurs_on_month, placeholder: 'Month', class: 'number', value: envelope.expense.occurs_on_month) +
        f2.text_field(:occurs_on_day, placeholder: 'Day', class: 'number', value: envelope.expense.occurs_on_day) +
        content_tag(:div, class: 'actions') do
          link_to("Cancel", "javascript:void(0)") +
          f2.button("Save", class: 'primary')
        end
      end
    end.to_str
  end
end
