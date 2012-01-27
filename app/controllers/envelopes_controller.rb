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
    
    # TODO: avoid dividing by 0
    funded = 1 #@envelope.amount_funded_this_month.abs
    spent = 1 #@envelope.amount_spent_this_month.abs
    max_spent_funded = [funded, spent].max
    
    @spent_percent = spent * 100 / max_spent_funded
    @funded_percent = funded * 100 / max_spent_funded
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
    
    if @envelope.save
      head :ok
    else
      render json: @envelope.errors, status: :unprocessable_entity
    end
  end

  def update
    envelope = Envelope.find(params[:id])
    authorize! :update, envelope

    if envelope.update_attributes(params[:envelope])
      head :ok
    else
      render json: envelope.errors, status: :unprocessable_entity
    end
  end

  def manage
    @new_envelope = Envelope.new

    @envelopes = Envelope.owned_by(current_user_id)
    @envelope_options_for_select = @envelopes.map {|envelope| [envelope.full_name(@envelopes), envelope.id] }
  end

end
