class AddColumnsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :bank_id, :string
    add_column :users, :bank_password_cipher, :string
    add_column :users, :bank_secret_questions, :string
  end
end
