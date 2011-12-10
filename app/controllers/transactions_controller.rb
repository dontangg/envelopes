class TransactionsController < ApplicationController
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
end