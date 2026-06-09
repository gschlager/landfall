# frozen_string_literal: true

class CreateMigratedPasswords < ActiveRecord::Migration[7.0]
  def change
    create_table :migrated_passwords do |t|
      t.bigint :user_id, null: false
      t.string :algorithm, null: false
      t.string :password_hash, null: false
      t.string :salt
      t.jsonb :metadata
      t.datetime :created_at, null: false
    end

    add_index :migrated_passwords, :user_id, unique: true
  end
end
