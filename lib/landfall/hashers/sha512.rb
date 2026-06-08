# frozen_string_literal: true

require "digest"

module Landfall
  module Hashers
    # Plain unsalted SHA512: sha512(password).
    module SHA512
      def self.match?(password:, hash:, salt:, metadata:)
        Digest::SHA512.hexdigest(password) == hash.downcase
      end
    end
  end
end
