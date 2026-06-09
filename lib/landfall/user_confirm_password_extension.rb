# frozen_string_literal: true

require_relative "legacy_login"

module Landfall
  # Prepended onto User. After Discourse's native password check fails, it falls back
  # to a stored legacy hash. A matched, policy-compliant password is re-hashed to
  # Discourse's native algorithm and the legacy record is deleted (used exactly once).
  #
  # A matched but non-compliant password is deliberately NOT stored here: persisting a
  # password that violates the current policy would be a security regression. That case
  # is handled by SessionController, which routes the user into the password-reset flow.
  module UserConfirmPasswordExtension
    def confirm_password?(password)
      return true if super
      return false unless Landfall::LegacyLogin.classify(self, password) == :compliant

      self.password = password
      save!
      migrated_password.destroy!
      true
    end
  end
end
