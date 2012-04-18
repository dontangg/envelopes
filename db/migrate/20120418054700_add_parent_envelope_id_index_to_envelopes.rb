class AddParentEnvelopeIdIndexToEnvelopes < ActiveRecord::Migration
  def change
    add_index :envelopes, :parent_envelope_id
  end
end
