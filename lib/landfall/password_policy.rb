# frozen_string_literal: true

module Landfall
  # Checks a candidate plaintext password against Discourse's *current* password
  # policy (min length, admin min length, blocked common passwords, unique
  # characters, ...) without persisting anything. It validates a throwaway
  # UserPassword associated with the real user, so admin/username/email/name aware
  # rules are honoured, and reads back the password errors.
  module PasswordPolicy
    def self.compliant?(user, password)
      candidate = UserPassword.new(user: user)
      candidate.password = password
      candidate.valid?
      candidate.errors[:password].blank?
    end
  end
end
