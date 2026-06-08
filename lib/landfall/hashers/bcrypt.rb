# frozen_string_literal: true

require "bcrypt"

module Landfall
  module Hashers
    # bcrypt hashes ($2a$/$2b$/$2y$...). Delegates to the bcrypt gem's own
    # constant-time comparison. Returns false for malformed hashes.
    #
    # The module is deliberately named `BCrypt` to mirror the gem: inside it a bare
    # `BCrypt` resolves here (not to the gem), so the explicit `::BCrypt` references
    # below are load-bearing and any stray non-rooted reference fails loudly.
    module BCrypt
      def self.match?(password:, hash:, salt:, metadata:)
        ::BCrypt::Password.new(hash) == password
      rescue ::BCrypt::Errors::InvalidHash
        false
      end
    end
  end
end
