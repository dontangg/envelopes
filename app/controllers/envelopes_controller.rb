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

    # A Hash with all the envelopes organized by parent_envelope_id
    @organized_envelopes = Envelope.organize(@all_envelopes)
    
    @start_date = params[:start_date].try(:to_date) || Date.today - 1.month
    @end_date = params[:end_date].try(:to_date) || Date.today

    # An array of transactions in this envelope
    @transactions = @envelope.all_transactions(@organized_envelopes).starting_at(@start_date).ending_at(@end_date)
  end

end
