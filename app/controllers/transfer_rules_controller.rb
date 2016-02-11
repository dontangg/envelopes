class TransferRulesController < ApplicationController
  def index
    @new_transfer_rule = TransferRule.new

    @transfer_rules = TransferRule.owned_by(current_user_id)

    all_envelopes = Envelope.owned_by(current_user_id)
    organized_envelopes = Envelope.organize(all_envelopes)

    @envelope_options_for_select = []
    all_envelopes.each do |envelope|
      @envelope_options_for_select << [envelope.full_name(all_envelopes), envelope.id] if organized_envelopes[envelope.id].empty?
    end
  end

  def create
    @transfer_rule = current_user.transfer_rules.build(transfer_rule_params)

    if @transfer_rule.save
      all_envelopes = Envelope.owned_by(current_user_id)
      organized_envelopes = Envelope.organize(all_envelopes)

      @envelope_options_for_select = []
      all_envelopes.each do |envelope|
        @envelope_options_for_select << [envelope.full_name(all_envelopes), envelope.id] if organized_envelopes[envelope.id].empty?
      end
    else
      render json: @transfer_rule.errors, status: :unprocessable_entity
    end
  end

  def update
    transfer_rule = TransferRule.find(params[:id])
    authorize! :update, transfer_rule

    if transfer_rule.update_attributes(transfer_rule_params)
      head :ok
    else
      render json: transfer_rule.errors, status: :unprocessable_entity
    end
  end

  def destroy
    transfer_rule = TransferRule.find(params[:id])
    authorize! :destroy, transfer_rule

    if transfer_rule.destroy
      head :ok
    else
      render json: transfer_rule.errors, status: :unprocessable_entity
    end
  end


  private

  def transfer_rule_params
    params.require(:transfer_rule).permit(:search_terms, :payee, :envelope_id, :percentage, :user_id, :envelope, :user)
  end

end
