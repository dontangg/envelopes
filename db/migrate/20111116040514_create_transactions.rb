class CreateTransactions < ActiveRecord::Migration
  def change
    create_table :transactions do |t|
      t.date :posted_at
      t.string :payee
      t.string :original_payee
      t.decimal :amount
      t.integer :from_envelope_id
      t.integer :to_envelope_id
      t.string :unique_id
      t.boolean :pending

      t.timestamps, null: false
    end

    change_table :transactions do |t|
      t.index :from_envelope_id
      t.index :to_envelope_id
      t.index :posted_at
    end
  end
end
