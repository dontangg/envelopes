class AddEnvelopeIdIndexForRules < ActiveRecord::Migration
  def change
    add_index :rules, :envelope_id
  end
end
