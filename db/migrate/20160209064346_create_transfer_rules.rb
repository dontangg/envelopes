class CreateTransferRules < ActiveRecord::Migration
  def change
    create_table :transfer_rules do |t|
      t.integer :user_id
      t.string :search_terms
      t.integer :envelope_id
      t.string :payee
      t.integer :percentage

      t.timestamps null: false
    end

    change_table :transfer_rules do |t|
      t.index :user_id
      t.index :envelope_id
    end
  end
end
