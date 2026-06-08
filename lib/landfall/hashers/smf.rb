# frozen_string_literal: true

require "digest"

module Landfall
  module Hashers
    # Simple Machines Forum: sha1(lowercase(username) + password). The username is
    # part of the input, so it must be supplied via metadata["username"] at import.
    module SMF
      def self.match?(password:, hash:, salt:, metadata:)
        username = metadata["username"]
        return false if username.nil?
        Digest::SHA1.hexdigest(username.downcase + password) == hash.downcase
      end
    end
  end
end
