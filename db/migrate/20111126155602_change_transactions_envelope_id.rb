class ChangeTransactionsEnvelopeId < ActiveRecord::Migration
  def change
    rename_column :transactions, :from_envelope_id, :envelope_id
    rename_column :transactions, :to_envelope_id, :associated_transaction_id
  end
end
