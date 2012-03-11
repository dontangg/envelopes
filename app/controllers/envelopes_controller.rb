class EnvelopesController < ApplicationController
  def index
    all_envelopes = Envelope.owned_by(current_user_id).with_amounts
    
    @organized_envelopes = Envelope.organize(all_envelopes)
  end

  def show
    # An array of all envelopes, used by transaction partial to create envelopes dropdown
    @all_envelopes = Envelope.owned_by(current_user_id).with_amounts

    # A Hash with all the envelopes organized by parent_envelope_id
    @organized_envelopes = Envelope.organize(@all_envelopes)

    # The envelope the user is currently looking at
    if params[:id].to_i == 0
      @envelope = @organized_envelopes['sys'].select {|envelope| envelope.id == 0 }.first
    else
      @envelope = @all_envelopes.select {|envelope| envelope.id == params[:id].to_i }.first
      raise CanCan::AccessDenied.new("Not authorized!", :read, Envelope) unless @envelope
    end

    @envelope_options_for_select = @all_envelopes.map {|envelope| [envelope.full_name(@all_envelopes), envelope.id] }
    
    @start_date = params[:start_date].try(:to_date) || Date.today - 1.month
    @end_date = params[:end_date].try(:to_date) || Date.today
    @show_transfers = params[:show_transfers]

    # An array of transactions in this envelope
    @transactions = @envelope.all_transactions(@organized_envelopes).starting_at(@start_date).ending_at(@end_date)
    @transactions = @transactions.without_transfers unless @show_transfers
    
    @budgeted_amount = @envelope.simple_monthly_budget
    @spent_amount = @envelope.amount_spent_this_month.abs
    max_spent_funded = [@budgeted_amount, @spent_amount].max

    @spent_percent = max_spent_funded == 0 ? 0 : @spent_amount * 100 / max_spent_funded
    @budgeted_percent = max_spent_funded == 0 ? 0 : @budgeted_amount * 100 / max_spent_funded
  end
  
  def fill
    all_envelopes = Envelope.owned_by(current_user_id).with_amounts
    Envelope.add_funded_this_month(all_envelopes, current_user_id)
    
    @organized_envelopes = Envelope.organize(all_envelopes)
    Envelope.calculate_suggestions(@organized_envelopes)
    
    @available_cash_envelope = @organized_envelopes['sys'].select {|envelope| envelope.income }.first
  end

  def perform_fill
    available_cash_envelope = Envelope.owned_by(current_user_id).income.first

    params.each do |key, value|
      match = /fill_envelope_(\d+)/.match(key)
      if match && match.length == 2
        amount = value.scan(/[-0-9.]+/).join.to_f
        
        if amount > 0
          to_envelope = Envelope.find(match[1])
          authorize! :update, to_envelope
        
          from_txn_payee = "Filled envelope: #{to_envelope.full_name}"
          to_txn_payee = "#{to_envelope.full_name} envelope filled"
          Transaction.create_transfer(amount, available_cash_envelope.id, to_envelope.id, from_txn_payee, to_txn_payee)
        end
      end
    end

    redirect_to envelopes_url
  end

  def create
    @envelope = Envelope.new(params[:envelope])
    @envelope.user_id = current_user_id
    
    params[:envelope][:expense] = Expense.new(params[:envelope][:expense]) if params[:envelope] && params[:envelope][:expense]

    if @envelope.save
      redirect_to manage_envelopes_url
    else
      render json: @envelope.errors, status: :unprocessable_entity
    end
  end

  def update
    @envelope = Envelope.find(params[:id])
    authorize! :update, @envelope

    # params[:envelope][:expense] = Expense.new(params[:envelope][:expense]) if params[:envelope] && params[:envelope][:expense]

    if @envelope.update_attributes(params[:envelope])
      #head :ok
      render
    else
      render json: @envelope.errors, status: :unprocessable_entity
    end
  end

  def manage
    @new_envelope = Envelope.new

    @all_envelopes = Envelope.owned_by(current_user_id)
    @organized_envelopes = Envelope.organize(@all_envelopes)

    @envelope_options_for_select = @all_envelopes.map {|envelope| [envelope.full_name(@all_envelopes), envelope.id] }
    @envelope_options_for_select.unshift ['', ''] 

    top_level_envelope_ids = @organized_envelopes[nil].map {|envelope| envelope.id }
    @envelope_options_for_create_select = [ ['', ''] ]
    @all_envelopes.each do |envelope|
      if envelope.parent_envelope_id.nil? || top_level_envelope_ids.include?(envelope.parent_envelope_id)
        @envelope_options_for_create_select.push [envelope.full_name(@all_envelopes), envelope.id] 
      end
    end

    @envelopes_with_transactions = []
    @all_envelopes.each do |envelope|
      if @organized_envelopes[envelope.id].size == 0
        @envelopes_with_transactions.push [envelope.full_name(@all_envelopes), envelope.id]
      end
    end
  end

  def destroy
    envelope = Envelope.find(params[:id])
    authorize! :destroy, envelope

    if envelope.transactions.count > 0
      if Envelope.find(params[:destination_envelope_id]) && params[:destination_envelope_id].to_i != envelope.id
        Envelope.move_transactions(envelope.id, params[:destination_envelope_id])
      else
        envelope.errors.add(" ", "You must specify a valid envelope to move the transactions into")
      end
    end

    if envelope.destroy
      redirect_to manage_envelopes_url
    else
      error_msg = envelope.errors.full_messages.join("\n")

      redirect_to manage_envelopes_url, alert: error_msg
    end
  end

end
