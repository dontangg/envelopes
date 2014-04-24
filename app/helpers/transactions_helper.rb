module TransactionsHelper

  def content_for_transaction_popover(transaction)
    content_tag(:div) do
      concat content_tag(:strong, 'Original Payee')
      concat content_tag(:p, transaction.original_payee)

      # TODO: Display memo/notes when they exist here
    end.to_str
  end

end

