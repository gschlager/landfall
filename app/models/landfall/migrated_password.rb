# frozen_string_literal: true

module Landfall
  # A legacy password hash imported from another forum, stored server-side only.
  # Created by the migration tooling; deleted automatically the first time the user
  # logs in with it (after re-hashing to Discourse's native algorithm).
  class MigratedPassword < ActiveRecord::Base
    self.table_name = "migrated_passwords"

    belongs_to :user

    validates :user_id, presence: true, uniqueness: true
    validates :algorithm, presence: true
    validates :password_hash, presence: true
  end
end

# == Schema Information
#
# Table name: migrated_passwords
#
#  id            :bigint           not null, primary key
#  user_id       :bigint           not null
#  algorithm     :string           not null
#  password_hash :string           not null
#  salt          :string
#  metadata      :jsonb
#  created_at    :datetime         not null
#
# Indexes
#
#  index_migrated_passwords_on_user_id  (user_id) UNIQUE
#
