# frozen_string_literal: true

require "digest"

module Landfall
  module Hashers
    # Plain unsalted MD5: md5(password). Hex comparison is case-insensitive because
    # legacy systems stored digests in either case.
    module MD5
      def self.match?(password:, hash:, salt:, metadata:)
        Digest::MD5.hexdigest(password) == hash.downcase
      end
    end
  end
end
