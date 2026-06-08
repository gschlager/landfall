# frozen_string_literal: true

module Landfall
  module Hashers
    # Unix crypt(3) hashes (DES, md5-crypt $1$, sha256-crypt $5$, sha512-crypt $6$).
    # The stored hash carries its own salt, so re-crypting the password with the
    # stored hash as the setting reproduces it when the password is correct.
    module Crypt
      def self.match?(password:, hash:, salt:, metadata:)
        password.crypt(hash) == hash
      end
    end
  end
end
