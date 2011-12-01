class EnvelopesController < ApplicationController
  def index
    all_envelopes = Envelope.owned_by(current_user_id).all_with_amounts
    
    @parent_envelopes = []
    @child_envelopes = Hash.new { |hash, key| hash[key] = [] }
    all_envelopes.each do |envelope|
      envelope_array = envelope.parent_envelope_id ? @child_envelopes[envelope.parent_envelope_id] : @parent_envelopes
      envelope_array.push(envelope)
    end
  end

  def show
  end

end
