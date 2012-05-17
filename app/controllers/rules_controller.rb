class RulesController < ApplicationController
  def index
    @new_rule = Rule.new

    @rules = Rule.owned_by(current_user_id)

    all_envelopes = Envelope.owned_by(current_user_id).sort
    @envelope_options_for_select = all_envelopes.map {|envelope| [envelope.full_name(all_envelopes), envelope.id] }
  end

  def create
    @rule = current_user.rules.build(params[:rule])

    if @rule.save
      all_envelopes = Envelope.owned_by(current_user_id).sort
      @envelope_options_for_select = all_envelopes.map {|envelope| [envelope.full_name(all_envelopes), envelope.id] }
    else
      render json: @rule.errors, status: :unprocessable_entity
    end
  end

  def update
    rule = Rule.find(params[:id])
    authorize! :update, rule

    if rule.update_attributes(params[:rule])
      head :ok
    else
      render json: rule.errors, status: :unprocessable_entity
    end
  end

  def destroy
    rule = Rule.find(params[:id])
    authorize! :destroy, rule

    if rule.destroy
      head :ok
    else
      render json: rule.errors, status: :unprocessable_entity
    end
  end

  def run_all
    rules = Rule.owned_by(current_user_id)

    @changed_count = 0
    Envelope.unassigned.first.transactions.without_transfers.each do |transaction|
      Rule.run_all(rules, transaction)
      if transaction.changed?
        @changed_count += 1 if transaction.save
      end
    end
  end

end
