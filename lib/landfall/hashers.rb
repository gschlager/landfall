# frozen_string_literal: true

module Landfall
  # Namespace for the pure, dependency-light legacy password hashers. Each hasher
  # exposes `match?(password:, hash:, salt:, metadata:)` and returns a boolean.
  module Hashers
  end
end

require_relative "hashers/md5"
require_relative "hashers/sha1"
require_relative "hashers/sha256"
require_relative "hashers/sha512"
require_relative "hashers/bcrypt"
require_relative "hashers/vbulletin"
require_relative "hashers/ipb"
require_relative "hashers/smf"
require_relative "hashers/joomla"
require_relative "hashers/crypt"
require_relative "hashers/phpass"
