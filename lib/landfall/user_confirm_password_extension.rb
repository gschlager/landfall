# frozen_string_literal: true

require_relative "legacy_password_verifier"

module Landfall
  # Prepended onto User. After Discourse's native password check fails, it falls back
  # to a stored legacy hash; on a match it re-hashes the password to Discourse's
  # native algorithm and deletes the legacy record so it is used exactly once.
  module UserConfirmPasswordExtension
    def confirm_password?(password)
      return true if super
      return false unless SiteSetting.landfall_login_with_old_password_enabled

      migrated = landfall_migrated_password
      return false if migrated.blank?

      matched =
        LegacyPasswordVerifier.matches?(
          algorithm: migrated.algorithm,
          hash: migrated.password_hash,
          password: password,
          salt: migrated.salt,
          metadata: migrated.metadata,
        )
      return false unless matched

      self.password = password
      save!
      migrated.destroy!
      true
    end
  end
end
