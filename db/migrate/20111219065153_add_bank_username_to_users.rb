class AddBankUsernameToUsers < ActiveRecord::Migration
  def change
    add_column :users, :bank_username, :string
  end
end
