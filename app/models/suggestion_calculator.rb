class SuggestionCalculator

  class << self

    def calculate(organized_envelopes)
      organized_envelopes[nil].each {|envelope| suggest_envelope(organized_envelopes, envelope) }
    end

    protected

    def suggest_envelope(organized_envelopes, current_envelope)
      # See if this envelope contains other envelopes
      if organized_envelopes[current_envelope.id].empty?
        if current_envelope.expense.nil?
          current_envelope.suggested_amount = 0.to_d
        else
          if current_envelope.expense.frequency == :monthly
            # If it is a monthly envelope, suggest the full amount
            current_envelope.suggested_amount = current_envelope.expense.amount
          else
            if current_envelope.expense.occurs_on_month.nil?
              # If it is a yearly envelope without a month, suggest the full amount / 12
              current_envelope.suggested_amount = current_envelope.expense.amount / 12.to_d
            else
              # If it is a yearly envelope with a date, complicate :)
              suggest_yearly(organized_envelopes, current_envelope)
            end
          end
        end

        puts "s: #{current_envelope.suggested_amount} f: #{current_envelope.amount_funded_this_month} #{current_envelope.suggested_amount - current_envelope.amount_funded_this_month}"
        current_envelope.suggested_amount = [current_envelope.suggested_amount - current_envelope.amount_funded_this_month, 0.to_d].max
        puts " #{current_envelope.suggested_amount}"
      else
        # If the envelope has other envelopes, it can't have an expense, so its suggestion is the sum of its children's suggestions
        current_envelope.suggested_amount = 0.to_d
        organized_envelopes[current_envelope.id].each do |child_envelope|
          current_envelope.suggested_amount += (suggest_envelope(organized_envelopes, child_envelope) || 0.to_d)
        end
      end

      current_envelope.suggested_amount
    end

    def suggest_yearly(organized_envelopes, current_envelope)
      return current_envelope.suggested_amount if current_envelope.suggested_amount.present?

      # Get all the envelopes with the same parent that are also yearly with a month
      yearlies = []
      organized_envelopes[current_envelope.parent_envelope_id].each do |envelope|
        if envelope.expense.try(:frequency) == :yearly && envelope.expense.occurs_on_month.present?
          months = envelope.expense.occurs_on_month
          months += 12 if envelope.expense.occurs_on_month < Date.today.month
          months -= Date.today.month - 1
          yearlies << {
            sort_by_key: "%02d%02d" % [months, envelope.expense.occurs_on_day || 1],
            number_of_months_before_due: months.to_d,
            envelope: envelope
          }
        end
      end

      # Order the envelopes by which is due next
      yearlies = yearlies.sort {|a, b| a[:sort_by_key] <=> b[:sort_by_key] }

      # Figure out how much to distribute between all these envelopes
      # For each envelope:
      # * Add up all the envelope amounts that are due up to when the current envelope is due (don't count money put in this month)
      # * Divide by the number of months left and take this number if is the highest so far
      total_amount = 0.to_d
      max_monthly = 0.to_d
      yearlies.each do |yearly|
        envelope_current_total = [yearly[:envelope].total_amount - yearly[:envelope].amount_funded_this_month, 0.to_d].max
        total_amount += yearly[:envelope].expense.amount - envelope_current_total
        max_monthly = [max_monthly, total_amount / yearly[:number_of_months_before_due]].max
      end

      # Take that amount and suggest it for the first envelope due
      # Take any extra and suggest it for the next envelope, etc.
      monthly_amount_left = max_monthly
      yearlies.each do |yearly|
        envelope = yearly[:envelope]

        amount_left_for_this_envelope = [envelope.expense.amount - envelope.total_amount, 0.to_d].max
        suggested_amount = [amount_left_for_this_envelope, monthly_amount_left].min
        
        monthly_amount_left -= suggested_amount
        envelope.suggested_amount = suggested_amount
      end
      
    end


  end

end
