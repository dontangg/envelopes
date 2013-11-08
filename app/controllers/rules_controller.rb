class RulesController < ApplicationController
  def index
    @new_rule = Rule.new

    @rules = Rule.owned_by(current_user_id)

    all_envelopes = Envelope.owned_by(current_user_id)
    organized_envelopes = Envelope.organize(all_envelopes)

    @envelope_options_for_select = [['No Change', nil]]
    all_envelopes.each do |envelope|
      @envelope_options_for_select << [envelope.full_name(all_envelopes), envelope.id] if organized_envelopes[envelope.id].empty?
    end
  end

  def create
    @rule = current_user.rules.build(rule_params)

    if @rule.save
      all_envelopes = Envelope.owned_by(current_user_id)
      organized_envelopes = Envelope.organize(all_envelopes)

      @envelope_options_for_select = [['No Change', nil]]
      all_envelopes.each do |envelope|
        @envelope_options_for_select << [envelope.full_name(all_envelopes), envelope.id] if organized_envelopes[envelope.id].empty?
      end
    else
      render json: @rule.errors, status: :unprocessable_entity
    end
  end

  def update
    rule = Rule.find(params[:id])
    authorize! :update, rule

    if rule.update_attributes(rule_params)
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
    Envelope.owned_by(current_user_id).unassigned.first.transactions.without_transfers.each do |transaction|
      Rule.run_all(rules, transaction)
      if transaction.changed?
        @changed_count += 1 if transaction.save
      end
    end
  end

  private

  def rule_params
    params.require(:rule).permit(:search_text, :replacement_text, :envelope_id, :order, :user_id, :envelope, :user)
  end

end
