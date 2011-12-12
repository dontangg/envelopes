class TransactionsController < ApplicationController
  include ActionView::Helpers::NumberHelper
  
  def update_all
    

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
  
  def create_transfer
    amount = params[:transfer_amount].scan(/[-0-9.]/).join.to_f
    from_envelope = Envelope.find(params[:transfer_from_id])
    to_envelope = Envelope.find(params[:transfer_to_id])
    
    from_txn_payee = "Transferred #{number_to_currency(amount)} to #{to_envelope.full_name}"
    from_txn = Transaction.create posted_at: Date.today, payee: from_txn_payee, original_payee: from_txn_payee, envelope_id: from_envelope.id, amount: -amount
    to_txn_payee = "Transferred #{number_to_currency(amount)} from #{from_envelope.full_name}"
    to_txn = Transaction.create posted_at: Date.today, payee: to_txn_payee, original_payee: to_txn_payee, envelope_id: to_envelope.id, amount: amount, associated_transaction_id: from_txn.id
    from_txn.associated_transaction_id = to_txn.id
    from_txn.save
    
    respond_to do |format|
      format.js
    end
  end
end