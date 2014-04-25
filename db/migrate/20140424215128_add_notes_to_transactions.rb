class AddNotesToTransactions < ActiveRecord::Migration
  def change
    add_column :transactions, :notes, :string
  end
end
