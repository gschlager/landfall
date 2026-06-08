# frozen_string_literal: true

require "digest"

module Landfall
  module Hashers
    # Invision Power Board (3.x): md5(md5(salt) + md5(password)), salt stored
    # separately.
    module IPB
      def self.match?(password:, hash:, salt:, metadata:)
        return false if salt.nil?
        Digest::MD5.hexdigest(Digest::MD5.hexdigest(salt) + Digest::MD5.hexdigest(password)) ==
          hash.downcase
      end
    end
  end
end
