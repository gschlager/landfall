# frozen_string_literal: true

class CreateLandfallOldUsernames < ActiveRecord::Migration[7.0]
  def change
    create_table :landfall_old_usernames do |t|
      t.bigint :user_id, null: false
      t.string :username, null: false
      t.string :username_lower, null: false
      t.datetime :created_at, null: false
    end

    add_index :landfall_old_usernames, :user_id
    add_index :landfall_old_usernames, :username_lower
  end
end
