# frozen_string_literal: true

require "digest"

module Landfall
  module Hashers
    # Joomla 1.x/2.5 legacy passwords: stored as "md5hex:salt" where the digest is
    # md5(password + salt). Older installs stored a bare md5(password) with no salt.
    # (Joomla 3+ bcrypt hashes are handled by the bcrypt hasher instead.)
    module Joomla
      def self.match?(password:, hash:, salt:, metadata:)
        digest, embedded_salt = hash.split(":", 2)
        expected =
          if embedded_salt.nil?
            Digest::MD5.hexdigest(password)
          else
            Digest::MD5.hexdigest(password + embedded_salt)
          end
        expected == digest.downcase
      end
    end
  end
end
