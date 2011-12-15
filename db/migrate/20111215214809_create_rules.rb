class CreateRules < ActiveRecord::Migration
  def change
    create_table :rules do |t|
      t.integer :user_id
      t.string :search_text
      t.string :replacement_text
      t.integer :envelope_id
      t.integer :order

      t.timestamps
    end

    change_table :rules do |t|
      t.index :user_id
      t.index :order
    end
  end
end
