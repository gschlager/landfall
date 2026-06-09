# frozen_string_literal: true

require_relative "legacy_password_verifier"
require_relative "password_policy"

module Landfall
  # Classifies a login attempt against what the migration knows about a user's password.
  module LegacyLogin
    # :none           - nothing to do (feature off, no record, or password mismatch)
    # :compliant      - legacy password matches and satisfies the current policy
    # :non_compliant  - legacy password matches but violates the current policy
    # :reset_required - the user has no usable imported password and must set one
    def self.classify(user, password)
      return :none unless SiteSetting.landfall_enabled

      migrated = user.landfall_migrated_password
      return :none if migrated.blank?

      if migrated.reset_required?
        return SiteSetting.landfall_force_password_reset_enabled ? :reset_required : :none
      end

      return :none unless SiteSetting.landfall_login_with_old_password_enabled
      return :none unless matches?(migrated, password)

      PasswordPolicy.compliant?(user, password) ? :compliant : :non_compliant
    end

    def self.matches?(migrated, password)
      LegacyPasswordVerifier.matches?(
        algorithm: migrated.algorithm,
        hash: migrated.password_hash,
        password: password,
        salt: migrated.salt,
        metadata: migrated.metadata,
      )
    end
  end
end
