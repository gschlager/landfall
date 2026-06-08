# frozen_string_literal: true

require "digest"

module Landfall
  module Hashers
    # Plain unsalted SHA1: sha1(password).
    module SHA1
      def self.match?(password:, hash:, salt:, metadata:)
        Digest::SHA1.hexdigest(password) == hash.downcase
      end
    end
  end
end
