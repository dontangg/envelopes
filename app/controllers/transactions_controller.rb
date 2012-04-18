class TransactionsController < ApplicationController
  include ActionView::Helpers::NumberHelper

  def update
    transaction = Transaction.find(params[:id])
    authorize! :update, transaction

    if params[:transaction] && params[:transaction][:amount]
      params[:transaction][:amount].gsub!(/[^-0-9.]+/, '')
    end

    if transaction.update_attributes(params[:transaction])
      head :ok
    else
      render json: transaction.errors, status: :unprocessable_entity
    end
  end

  def update_all
    # If you do want to do this, make sure you remove the dollar sign from the amount so that it doesn't just save zeroes
    #Transaction.update params[:transaction].keys, params[:transaction].values if params[:transaction]

    respond_to do |format|
      format.html { redirect_to envelope_url(params[:envelope_id], start_date: params[:start_date], end_date: params[:end_date]) }
      format.js do
        @all_envelopes = Envelope.owned_by(current_user_id)

        # A Hash with all the envelopes organized by parent_envelope_id
        @organized_envelopes = Envelope.organize(@all_envelopes)

        # The envelope the user is currently looking at
        if params[:envelope_id].to_i == 0
          @envelope = @organized_envelopes['sys'].select {|envelope| envelope.id == 0 }.first
        else
          @envelope = @all_envelopes.select {|envelope| envelope.id == params[:envelope_id].to_i }.first
          raise CanCan::AccessDenied.new("Not authorized!", :read, Envelope) unless @envelope
        end

        @envelope_options_for_select = @all_envelopes.map {|envelope| [envelope.full_name(@all_envelopes), envelope.id] }

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
    amount = params[:transfer_amount].gsub(/[^-0-9.]/, '').to_d

    if amount > 0 && params[:transfer_from_id] != params[:transfer_to_id]
      @attempted_transfer = true

      from_envelope = Envelope.find(params[:transfer_from_id])
      to_envelope = Envelope.find(params[:transfer_to_id])
      authorize! :update, from_envelope
      authorize! :update, to_envelope

      from_txn_payee = "Transferred #{number_to_currency(amount)} to #{to_envelope.full_name}"
      to_txn_payee = "Transferred #{number_to_currency(amount)} from #{from_envelope.full_name}"
      Transaction.create_transfer(amount, from_envelope.id, to_envelope.id, from_txn_payee, to_txn_payee)

      current_envelope = case params[:current_envelope_id].to_i
      when from_envelope.id
        from_envelope
      when to_envelope.id
        to_envelope
      else
        Envelope.find(params[:current_envelope_id])
      end

      @new_balance = current_envelope.inclusive_total_amount

      @budgeted_amount = current_envelope.simple_monthly_budget
      @spent_amount = current_envelope.amount_spent_this_month.abs
      max_spent_funded = [@budgeted_amount, @spent_amount].max

      @spent_percent = max_spent_funded == 0 ? 0 : @spent_amount * 100 / max_spent_funded
      @budgeted_percent = max_spent_funded == 0 ? 0 : @budgeted_amount * 100 / max_spent_funded
    else
      @attempted_transfer = false
    end

    respond_to do |format|
      format.js
    end
  end

  def import
    @import_count = TransactionImporter.auto_import(current_user_id)

    respond_to do |format|
      format.js
    end
  end
end
