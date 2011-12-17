class TransactionsController < ApplicationController
  include ActionView::Helpers::NumberHelper

  def update
    transaction = Transaction.find(params[:id])
    
    if params[:transaction] && params[:transaction][:amount]
      params[:transaction][:amount] = params[:transaction][:amount].scan(/[-0-9.]+/).join
    end

    if transaction.update_attributes(params[:transaction])
      head :ok
    else
      render json: transaction.errors, status: :unprocessable_entity
    end
  end
  
  def update_all
    # If you do want to do this, make sure you remove the dollar sign so that it doesn't just save zeroes
    #Transaction.update params[:transaction].keys, params[:transaction].values if params[:transaction]

    respond_to do |format|
      format.html { redirect_to envelope_url(params[:envelope_id], start_date: params[:start_date], end_date: params[:end_date]) }
      format.js do
        @all_envelopes = Envelope.owned_by(current_user_id)

        @envelope = @all_envelopes.select { |envelope| envelope.id == params[:envelope_id].to_i }.first

        @organized_envelopes = Envelope.organize(@all_envelopes)

        @start_date = Date.parse(params[:start_date]) || Date.today - 1.month
        @end_date = Date.parse(params[:end_date]) || Date.today
        @show_transfers = params[:show_transfers]

        # An array of transactions in this envelope
        @transactions = @envelope.all_transactions(@organized_envelopes).starting_at(@start_date).ending_at(@end_date)
        @transactions = @transactions.without_transfers unless @show_transfers
      end
    end
  end
  
  def suggest_payee
    
    term = params[:term].downcase
    
    all_payees = Transaction.payee_suggestions_for_user_id(current_user_id, term, params[:original])
    
    groups = [[], [], [], []]
    
    all_payees.each do |payee|
      payee_downcase = payee.downcase
      
      if payee_downcase.starts_with?("^" + term)
        groups[0] << payee
      elsif payee_downcase.include?(" #{term}")
        groups[1] << payee
      elsif Regexp.escape(payee_downcase).match("\b" + term)
        groups[2] << payee
      else
        groups[3] << payee
      end
    end
    
    words = groups.flatten.uniq.take(6)
    
    render json: words
  end
  
  def create_transfer
    amount = params[:transfer_amount].scan(/[-0-9.]+/).join.to_f

    if amount > 0
      from_envelope = Envelope.find(params[:transfer_from_id])
      to_envelope = Envelope.find(params[:transfer_to_id])
      
      from_txn_payee = "Transferred #{number_to_currency(amount)} to #{to_envelope.full_name}"
      from_txn = Transaction.create posted_at: Date.today, payee: from_txn_payee, original_payee: from_txn_payee, envelope_id: from_envelope.id, amount: -amount
      to_txn_payee = "Transferred #{number_to_currency(amount)} from #{from_envelope.full_name}"
      to_txn = Transaction.create posted_at: Date.today, payee: to_txn_payee, original_payee: to_txn_payee, envelope_id: to_envelope.id, amount: amount, associated_transaction_id: from_txn.id
      from_txn.associated_transaction_id = to_txn.id
      from_txn.save

      current_envelope = case params[:current_envelope_id].to_i
      when from_envelope.id
        from_envelope
      when to_envelope.id
        to_envelope
      else
        Envelope.find(params[:current_envelope_id])
      end

      @new_balance = current_envelope.inclusive_total_amount
    end

    # TODO: update transactions if currently viewing envelope transfers
    
    respond_to do |format|
      format.js
    end
  end
end