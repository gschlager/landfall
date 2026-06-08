# frozen_string_literal: true

require "digest"

module Landfall
  module Hashers
    # vBulletin (3.x/4.x): md5(md5(password) + salt), salt stored separately.
    module VBulletin
      def self.match?(password:, hash:, salt:, metadata:)
        return false if salt.nil?
        Digest::MD5.hexdigest(Digest::MD5.hexdigest(password) + salt) == hash.downcase
      end
    end
  end
end
