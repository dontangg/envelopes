class EnvelopesController < ApplicationController
  def index
    all_envelopes = Envelope.owned_by(current_user_id).with_amounts
    
    @envelopes = Envelope.organize(all_envelopes)
  end

  def show
    # An array of all envelopes, used by transaction partial to get full envelope name
    @all_envelopes = Envelope.owned_by(current_user_id).with_amounts

    # The envelope the user is currently looking at
    @envelope = @all_envelopes.select { |envelope| envelope.id == params[:id].to_i }.first

    # A Hash with all the envelopes organized by parent_envelope_id
    @envelopes = Envelope.organize(@all_envelopes)
    
    # An array of transactions in this envelope
    @transactions = @envelope.transactions.recent
  end

end
