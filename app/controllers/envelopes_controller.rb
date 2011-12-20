class EnvelopesController < ApplicationController
  def index
    all_envelopes = Envelope.owned_by(current_user_id).with_amounts
    
    @organized_envelopes = Envelope.organize(all_envelopes)
  end

  def show
    # An array of all envelopes, used by transaction partial to create envelopes dropdown
    @all_envelopes = Envelope.owned_by(current_user_id).with_amounts

    # The envelope the user is currently looking at
    @envelope = @all_envelopes.select { |envelope| envelope.id == params[:id].to_i }.first
    raise CanCan::AccessDenied.new("Not authorized!", :read, Envelope) unless @envelope
    
    # A Hash with all the envelopes organized by parent_envelope_id
    @organized_envelopes = Envelope.organize(@all_envelopes)
    
    @start_date = params[:start_date].try(:to_date) || Date.today - 1.month
    @end_date = params[:end_date].try(:to_date) || Date.today
    @show_transfers = params[:show_transfers]

    # An array of transactions in this envelope
    @transactions = @envelope.all_transactions(@organized_envelopes).starting_at(@start_date).ending_at(@end_date)
    @transactions = @transactions.without_transfers unless @show_transfers
    
    funded = @envelope.funded_this_month.abs
    spent = @envelope.spent_this_month.abs
    max_spent_funded = [funded, spent].max
    
    @spent_percent = spent * 100 / max_spent_funded
    @funded_percent = funded * 100 / max_spent_funded
  end
  
  def fill
    
  end

end
