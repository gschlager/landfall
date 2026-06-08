# frozen_string_literal: true

require "spec_helper"
require "digest"
require_relative "../../../lib/landfall/legacy_password_verifier"

# Fixtures generated independently of this code:
#   * plain digests, vBulletin, IPB, SMF, Joomla, crypt -> PHP 8.4
#   * bcrypt -> the bcrypt gem
#   * phpass -> passlib's phpass implementation
# All for the password "password".
RSpec.describe Landfall::LegacyPasswordVerifier do
  PASSWORD = "password"

  # algorithm => [hash, salt, metadata]
  FIXTURES = {
    "md5" => ["5f4dcc3b5aa765d61d8327deb882cf99", nil, nil],
    "sha1" => ["5baa61e4c9b93f3f0682250b6cf8331b7ee68fd8", nil, nil],
    "sha256" => ["5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8", nil, nil],
    "sha512" => [
      "b109f3bbbc244eb82441917ed06d618b9008dd09b3befd1b5e07394c706a8bb980b1d7785e5976ec049b46df5f1326af5a2ea6d103fd07c95385ffab0cacbc86",
      nil,
      nil,
    ],
    "bcrypt" => ["$2a$04$fPpywJpN.uHjS3vEAQYmv.PgvM8ZoDMq8e11YCVTb1za/Iqs8cuXC", nil, nil],
    "vbulletin" => ["10c2a543bc1fe85d7b5c9d6a0121f934", "Xy3", nil],
    "ipb" => ["ede82a7d525c5c176cb3b3abf3e427c1", "Xy3", nil],
    "smf" => ["744b6203c9aef01c9c9a8563838c8f71767b15bc", nil, { "username" => "Alice" }],
    "joomla" => ["a9d5f9213a6634255d962ae3a2fd1313:Xy3", nil, nil],
    "crypt" => ["abJnggxhB/yWI", nil, nil],
    "phpass" => ["$P$9aaaaaaaapfq1isZeLdu4Un4umlr.W1", nil, nil],
  }.freeze

  def verify(password, algorithm:, hash:, salt:, metadata:)
    described_class.matches?(
      algorithm: algorithm,
      hash: hash,
      password: password,
      salt: salt,
      metadata: metadata,
    )
  end

  FIXTURES.each do |algorithm, (hash, salt, metadata)|
    context "with #{algorithm}" do
      it "accepts the correct password" do
        expect(verify(PASSWORD, algorithm: algorithm, hash: hash, salt: salt, metadata: metadata)).to eq(true)
      end

      it "rejects a wrong password" do
        expect(verify("wrong", algorithm: algorithm, hash: hash, salt: salt, metadata: metadata)).to eq(false)
      end
    end
  end

  # Stored hex digests appear in either case across legacy systems.
  %w[md5 sha1 sha256 sha512 vbulletin ipb smf].each do |algorithm|
    it "matches #{algorithm} regardless of stored hash case" do
      hash, salt, metadata = FIXTURES.fetch(algorithm)
      expect(verify(PASSWORD, algorithm: algorithm, hash: hash.upcase, salt: salt, metadata: metadata)).to eq(true)
    end
  end

  it "uppercases nothing for the algorithm name yet matches case-insensitively" do
    hash, = FIXTURES.fetch("md5")
    expect(verify(PASSWORD, algorithm: "MD5", hash: hash, salt: nil, metadata: nil)).to eq(true)
  end

  describe "salted algorithms require their salt" do
    it "returns false for vbulletin without a salt" do
      hash, = FIXTURES.fetch("vbulletin")
      expect(verify(PASSWORD, algorithm: "vbulletin", hash: hash, salt: nil, metadata: nil)).to eq(false)
    end

    it "returns false for ipb without a salt" do
      hash, = FIXTURES.fetch("ipb")
      expect(verify(PASSWORD, algorithm: "ipb", hash: hash, salt: nil, metadata: nil)).to eq(false)
    end

    it "returns false for smf without a username in metadata" do
      hash, = FIXTURES.fetch("smf")
      expect(verify(PASSWORD, algorithm: "smf", hash: hash, salt: nil, metadata: {})).to eq(false)
    end
  end

  describe "joomla variants" do
    it "verifies a bare md5(password) with no embedded salt" do
      bare = "5f4dcc3b5aa765d61d8327deb882cf99"
      expect(verify(PASSWORD, algorithm: "joomla", hash: bare, salt: nil, metadata: nil)).to eq(true)
    end

    it "matches regardless of the stored digest case" do
      hash, = FIXTURES.fetch("joomla")
      digest, salt = hash.split(":", 2)
      expect(verify(PASSWORD, algorithm: "joomla", hash: "#{digest.upcase}:#{salt}", salt: nil, metadata: nil)).to eq(true)
    end

    it "treats only the first colon as the digest separator (salt may contain colons)" do
      salt = "a:b:c"
      digest = Digest::MD5.hexdigest(PASSWORD + salt)
      expect(verify(PASSWORD, algorithm: "joomla", hash: "#{digest}:#{salt}", salt: nil, metadata: nil)).to eq(true)
    end
  end

  describe "phpass / bcrypt rejection of malformed hashes" do
    it "returns false for a phpass hash with the wrong prefix" do
      expect(verify(PASSWORD, algorithm: "phpass", hash: "$Q$9aaaaaaaapfq1isZeLdu4Un4umlr.W1", salt: nil, metadata: nil)).to eq(false)
    end

    it "returns false for a malformed bcrypt hash" do
      expect(verify(PASSWORD, algorithm: "bcrypt", hash: "not-a-bcrypt-hash", salt: nil, metadata: nil)).to eq(false)
    end

    it "returns false for crypt with an empty hash" do
      expect(verify(PASSWORD, algorithm: "crypt", hash: "", salt: nil, metadata: nil)).to eq(false)
    end
  end

  describe "dispatcher guards" do
    it "returns false for an unknown algorithm" do
      expect(verify(PASSWORD, algorithm: "rot13", hash: "x", salt: nil, metadata: nil)).to eq(false)
    end

    it "returns false for a nil algorithm" do
      expect(verify(PASSWORD, algorithm: nil, hash: "x", salt: nil, metadata: nil)).to eq(false)
    end

    it "returns false for a blank hash" do
      expect(verify(PASSWORD, algorithm: "md5", hash: "", salt: nil, metadata: nil)).to eq(false)
    end

    it "returns false for a nil hash" do
      expect(verify(PASSWORD, algorithm: "md5", hash: nil, salt: nil, metadata: nil)).to eq(false)
    end

    it "returns false for a blank password" do
      hash, = FIXTURES.fetch("md5")
      expect(verify("", algorithm: "md5", hash: hash, salt: nil, metadata: nil)).to eq(false)
    end

    it "returns false for a nil password" do
      hash, = FIXTURES.fetch("md5")
      expect(verify(nil, algorithm: "md5", hash: hash, salt: nil, metadata: nil)).to eq(false)
    end

    it "tolerates nil metadata for algorithms that ignore it" do
      hash, = FIXTURES.fetch("md5")
      expect(verify(PASSWORD, algorithm: "md5", hash: hash, salt: nil, metadata: nil)).to eq(true)
    end
  end

  describe "optional keyword defaults" do
    it "defaults salt and metadata when omitted" do
      hash, = FIXTURES.fetch("md5")
      expect(described_class.matches?(algorithm: "md5", hash: hash, password: PASSWORD)).to eq(true)
    end

    it "passes an empty hash (not nil) to hashers when metadata is omitted" do
      hash, = FIXTURES.fetch("smf")
      # SMF needs metadata["username"]; with metadata defaulted it must not match
      # and must not raise.
      expect(described_class.matches?(algorithm: "smf", hash: hash, password: PASSWORD)).to eq(false)
    end
  end
end
