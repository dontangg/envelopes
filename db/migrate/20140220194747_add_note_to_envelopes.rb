class AddNoteToEnvelopes < ActiveRecord::Migration
  def change
    add_column :envelopes, :note, :text
  end
end
