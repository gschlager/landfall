# frozen_string_literal: true

class CreateMigratedUsernames < ActiveRecord::Migration[7.0]
  def change
    create_table :migrated_usernames do |t|
      t.bigint :user_id, null: false
      t.string :username, null: false
      t.string :username_lower, null: false
      t.datetime :created_at, null: false
    end

    add_index :migrated_usernames, :user_id
    add_index :migrated_usernames, :username_lower
  end
end
