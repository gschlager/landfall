# frozen_string_literal: true

require "digest"

module Landfall
  module Hashers
    # Plain unsalted SHA256: sha256(password).
    module SHA256
      def self.match?(password:, hash:, salt:, metadata:)
        Digest::SHA256.hexdigest(password) == hash.downcase
      end
    end
  end
end
