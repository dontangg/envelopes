class EnvelopesController < ApplicationController
  def index

    respond_to do |format|
      format.html
      format.json {
        all_envelopes = Envelope.owned_by(current_user_id).with_amounts
        organized_envelopes = Envelope.organize(all_envelopes)

        render json: organized_envelopes
      }
    end

  end

  def show
    render "index"
    return

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

    # Only suggest envelopes that don't contain other envelopes
    @envelope_options_for_select = []
    @all_envelopes.each do |envelope|
      @envelope_options_for_select << [envelope.full_name(@all_envelopes), envelope.id] if @organized_envelopes[envelope.id].empty?
    end

    @start_date = params[:start_date].try(:to_date) || Date.today - 1.month
    @end_date = params[:end_date].try(:to_date) || Date.today
    @show_transfers = session[:show_transfers] || params[:show_transfers]

    # An array of transactions in this envelope
    @transactions = @envelope.all_transactions(@organized_envelopes).starting_at(@start_date).ending_at(@end_date)
    @transactions = @transactions.without_transfers unless @show_transfers

    @show_graphs = @envelope.expense.try(:frequency) == :monthly && @organized_envelopes[@envelope.id].empty? && !@envelope.unassigned? && !@envelope.pending?

    if @show_graphs
      @budgeted_amount = @envelope.simple_monthly_budget
      @spending_months = @envelope.monthly_report(@envelope.income? ? :earnings : :spending, current_user_id)

      max_amount = @spending_months.inject(@budgeted_amount) { |max, month_data| [max, month_data[:amount].abs].max }

      @budgeted_percent = max_amount == 0 ? 0 : @budgeted_amount * 100 / max_amount

      @spending_months.each do |month_data|
        month_data[:amount] = month_data[:amount].abs
        month_data[:percent] = max_amount == 0 ? 0 : month_data[:amount] * 100 / max_amount
      end
    end
  end

  def fill
    all_envelopes = Envelope.owned_by(current_user_id).with_amounts
    Envelope.add_funded_this_month(all_envelopes, current_user_id)

    @organized_envelopes = Envelope.organize(all_envelopes)
    SuggestionCalculator.calculate(@organized_envelopes)

    @available_cash_envelope = @organized_envelopes['sys'].select {|envelope| envelope.income }.first
  end

  def perform_fill
    available_cash_envelope = Envelope.owned_by(current_user_id).income.first

    params.each do |key, value|
      match = /fill_envelope_(\d+)/.match(key)
      if match && match.length == 2
        amount = value.gsub(/[^-0-9.]/, '').to_d

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
    @envelope = current_user.envelopes.build(envelope_params)

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

    params[:envelope][:expense][:amount].gsub!(/[^-0-9.]/, '') if params[:envelope][:expense] && params[:envelope][:expense][:amount]

    # params[:envelope][:expense] = Expense.new(params[:envelope][:expense]) if params[:envelope] && params[:envelope][:expense]

    if @envelope.update_attributes(envelope_params)
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

    top_level_envelope_ids = @organized_envelopes[nil].map {|envelope| envelope.id }
    @envelope_options_for_create_select = [ ['None', ''] ]
    @all_envelopes.each do |envelope|
      unless envelope.income? || envelope.unassigned? || envelope.pending?
        # Only include 1st or 2nd level envelopes
        if envelope.parent_envelope_id.nil? || top_level_envelope_ids.include?(envelope.parent_envelope_id)
          @envelope_options_for_create_select << [envelope.full_name(@all_envelopes), envelope.id]
        end
      end
    end

    @envelopes_with_transactions = []
    @all_envelopes.each do |envelope|
      # Only include envelopes that do not contain other envelopes
      if @organized_envelopes[envelope.id].size == 0
        @envelopes_with_transactions << [envelope.full_name(@all_envelopes), envelope.id]
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

  private

  def envelope_params
    params.require(:envelope)
      .permit(
        :name,
        :parent_envelope_id,
        :user_id,
        :user,
        :parent_envelope,
        :note,
        expense: [:amount, :frequency, :occurs_on_day, :occurs_on_month]
      )
  end

end
