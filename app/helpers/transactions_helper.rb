module TransactionsHelper

  def content_for_transaction_popover(transaction)
    content_tag(:div) do
      concat content_tag(:h4, 'Original Payee')
      concat content_tag(:div, transaction.original_payee)

      if transaction.notes.present?
        concat content_tag(:h4, 'Notes')
        concat content_tag(:div, transaction.notes, class: 'notes')
      end
    end.to_str
  end

end

