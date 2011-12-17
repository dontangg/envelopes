class RulesController < ApplicationController
  def index
    @new_rule = Rule.new
    
    @rules = Rule.owned_by(current_user_id)
    @all_envelopes = Envelope.owned_by(current_user_id).sort
  end

  def create
    @rule = Rule.new(params[:rule])
    @rule.user_id = current_user_id
    
    if @rule.save
      @all_envelopes = Envelope.owned_by(current_user_id).sort
    else
      render json: @rule.errors, status: :unprocessable_entity
    end
  end

  def update
    rule = Rule.find(params[:id])

    if rule.update_attributes(params[:rule])
      head :ok
    else
      render json: rule.errors, status: :unprocessable_entity
    end
  end

  def destroy
    rule = Rule.find(params[:id])

    if rule.destroy
      head :ok
    else
      render json: rule.errors, status: :unprocessable_entity
    end
  end

end
