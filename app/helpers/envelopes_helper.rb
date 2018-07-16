module EnvelopesHelper
  def stringify_expense_frequency(expense)
    str = ""

    if expense.frequency == :monthly
      if expense.occurs_on_day
        day = expense.occurs_on_day >= 28 ? "last" : expense.occurs_on_day.ordinalize
        str += "on the #{day} day of "
      end
      str += "every month"
    elsif expense.frequency == :bimonthly
      str += "twice a month"
    else
      if expense.occurs_on_month
        if expense.occurs_on_day
          str += "on #{Date::MONTHNAMES[expense.occurs_on_month.to_i]} #{expense.occurs_on_day.to_i.ordinalize} "
        else
          str += "in #{Date::MONTHNAMES[expense.occurs_on_month.to_i]} "
        end
      end
      str += "every year"
    end
  end

  def content_for_frequency_popover(envelope)
    form_for(envelope, remote: true, html: { class: 'form-horizontal' }) do |f|
      f.fields_for(:expense) do |f2|
        content_tag(:div, class: 'form-group col-sm-11', style: 'width:200px') do
          f2.label(:frequency_bimonthly, class: 'radio-inline') do
            f2.radio_button(:frequency, :bimonthly, checked: envelope.expense.frequency == :bimonthly) +
            " Bi-Monthly"
          end +
          f2.label(:frequency_monthly, class: 'radio-inline') do
            f2.radio_button(:frequency, :monthly, checked: envelope.expense.frequency == :monthly) +
            " Monthly"
          end +
          f2.label(:frequency_yearly, class: 'radio-inline') do
            f2.radio_button(:frequency, :yearly, checked: envelope.expense.frequency == :yearly) +
            " Yearly"
          end
        end +
        content_tag(:div, class: 'form-group') do
          f2.label(:occurs_on_month, "Month", class: 'control-label col-sm-6') +
          f2.text_field(:occurs_on_month, placeholder: 'Month', class: 'number form-control col-sm-6', value: envelope.expense.occurs_on_month)
        end +
        content_tag(:div, class: 'form-group') do
          f2.label(:occurs_on_day, "Day", class: 'control-label col-sm-6') +
          f2.text_field(:occurs_on_day, placeholder: 'Day', class: 'number form-control col-sm-6', value: envelope.expense.occurs_on_day)
        end +
        content_tag(:div, class: 'actions') do
          button_tag("Cancel", type: 'button', class: "btn btn-default") +
          f2.button("Save", class: 'btn btn-primary')
        end
      end
    end.to_str
  end
end
