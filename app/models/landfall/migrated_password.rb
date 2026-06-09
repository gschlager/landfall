# frozen_string_literal: true

module Landfall
  # What the migration knows about an imported user's password, stored server-side
  # only. Two shapes:
  #   * a legacy hash (algorithm + password_hash [+ salt/metadata]) the user can log in
  #     with once, after which it is re-hashed natively and the row is deleted; or
  #   * a "reset required" marker (reset_required: true, no hash) for users whose
  #     password could not be imported — they are routed to set a new password on login.
  class MigratedPassword < ActiveRecord::Base
    self.table_name = "migrated_passwords"

    belongs_to :user

    validates :user_id, presence: true, uniqueness: true
    validates :algorithm, presence: true, unless: :reset_required?
    validates :password_hash, presence: true, unless: :reset_required?
  end
end

# == Schema Information
#
# Table name: migrated_passwords
#
#  id             :bigint           not null, primary key
#  user_id        :bigint           not null
#  algorithm      :string
#  password_hash  :string
#  salt           :string
#  metadata       :jsonb
#  reset_required :boolean          default(FALSE), not null
#  created_at     :datetime         not null
#
# Indexes
#
#  index_migrated_passwords_on_user_id  (user_id) UNIQUE
#
