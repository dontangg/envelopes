class AddIndexToUserIdOnEnvelopes < ActiveRecord::Migration
  def change
    add_index :envelopes, :user_id
  end
end
