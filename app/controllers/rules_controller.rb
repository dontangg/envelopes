class RulesController < ApplicationController
  def index
    @rules = Rule.owned_by(current_user_id)
    @all_envelopes = Envelope.owned_by(current_user_id)
  end

  def create
  end

  def update
  end

  def destroy
  end

end
