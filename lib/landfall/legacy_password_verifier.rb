# frozen_string_literal: true

require_relative "hashers"

module Landfall
  # Pure dispatch from an algorithm name to its hasher. Non-mutating: it only checks
  # whether a candidate password reproduces a stored legacy hash. Unknown algorithms
  # and blank inputs return false.
  module LegacyPasswordVerifier
    HASHERS = {
      "md5" => Hashers::MD5,
      "sha1" => Hashers::SHA1,
      "sha256" => Hashers::SHA256,
      "sha512" => Hashers::SHA512,
      "bcrypt" => Hashers::BCrypt,
      "vbulletin" => Hashers::VBulletin,
      "ipb" => Hashers::IPB,
      "smf" => Hashers::SMF,
      "joomla" => Hashers::Joomla,
      "crypt" => Hashers::Crypt,
      "phpass" => Hashers::Phpass,
    }.freeze

    def self.matches?(algorithm:, hash:, password:, salt: nil, metadata: nil)
      hasher = HASHERS[algorithm.to_s.downcase]
      return false unless hasher
      return false if hash.to_s.empty?
      return false if password.to_s.empty?
      hasher.match?(password: password, hash: hash, salt: salt, metadata: metadata || {})
    end
  end
end
