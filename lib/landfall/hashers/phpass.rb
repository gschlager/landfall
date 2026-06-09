# frozen_string_literal: true

require "digest"

module Landfall
  module Hashers
    # Portable PHP password hashes ("phpass"), used by WordPress ($P$) and phpBB3
    # ($H$). Implementation of the well-known public-domain algorithm by
    # Solar Designer. Cross-validated against passlib's phpass vectors.
    module Phpass
      ITOA64 = "./0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"

      def self.match?(password:, hash:, salt:, metadata:)
        crypt(password, hash) == hash
      end

      def self.crypt(password, setting)
        prefix = setting[0, 3]
        return "*0" if prefix != "$P$" && prefix != "$H$"

        count_log2 = ITOA64.index(setting[3])
        return "*0" if count_log2.nil? || count_log2 < 7 || count_log2 > 30

        salt = setting[4, 8]
        return "*0" if salt.length != 8

        digest = Digest::MD5.digest(salt + password)
        (1 << count_log2).times { digest = Digest::MD5.digest(digest + password) }

        setting[0, 12] + encode64(digest, 16)
      end

      def self.encode64(input, count)
        output = +""
        i = 0
        while i < count
          value = input.getbyte(i)
          i += 1
          output << ITOA64[value & 0x3f]
          value |= input.getbyte(i) << 8 if i < count
          output << ITOA64[(value >> 6) & 0x3f]
          i += 1
          break if i >= count
          value |= input.getbyte(i) << 16 if i < count
          output << ITOA64[(value >> 12) & 0x3f]
          i += 1
          output << ITOA64[(value >> 18) & 0x3f]
        end
        output
      end
    end
  end
end
