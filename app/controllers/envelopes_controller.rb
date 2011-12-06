class EnvelopesController < ApplicationController
  def index
    all_envelopes = Envelope.owned_by(current_user_id).with_amounts
    
    @envelopes = Envelope.organize(all_envelopes)
  end

  def show
    all_envelopes = Envelope.owned_by(current_user_id).with_amounts
    
    @envelopes = Envelope.organize(all_envelopes)
    @envelope = all_envelopes.select { |envelope| envelope.id == params[:id].to_i }.first
    
    @transactions = @envelope.transactions.recent
  end

end
