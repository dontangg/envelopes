class AddBankAccountIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :bank_account_id, :string
  end
end
