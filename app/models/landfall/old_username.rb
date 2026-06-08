# frozen_string_literal: true

module Landfall
  # A username a user had before the migration renamed them. Stored server-side only;
  # one row per prior username. `username_lower` is indexed for exact login lookups.
  class OldUsername < ActiveRecord::Base
    self.table_name = "landfall_old_usernames"

    belongs_to :user

    validates :user_id, presence: true
    validates :username, presence: true

    before_validation :normalize

    private

    def normalize
      self.username_lower = User.normalize_username(username) if username.present?
    end
  end
end

# == Schema Information
#
# Table name: landfall_old_usernames
#
#  id             :bigint           not null, primary key
#  user_id        :bigint           not null
#  username       :string           not null
#  username_lower :string           not null
#  created_at     :datetime         not null
#
# Indexes
#
#  index_landfall_old_usernames_on_user_id         (user_id)
#  index_landfall_old_usernames_on_username_lower  (username_lower)
#
