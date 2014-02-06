class AddPendingToEnvelopes < ActiveRecord::Migration
  def change
    add_column :envelopes, :pending, :boolean
  end
end
