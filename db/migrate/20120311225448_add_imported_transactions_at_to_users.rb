class AddImportedTransactionsAtToUsers < ActiveRecord::Migration
  def change
    add_column :users, :imported_transactions_at, :datetime
  end
end
