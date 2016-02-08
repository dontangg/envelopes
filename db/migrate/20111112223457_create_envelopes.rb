class CreateEnvelopes < ActiveRecord::Migration
  def change
    create_table :envelopes do |t|
      t.string  :name
      t.integer :user_id
      t.boolean :income
      t.boolean :unassigned
      t.integer :parent_envelope_id
      t.string  :expense

      t.timestamps, null: false
    end
  end
end
