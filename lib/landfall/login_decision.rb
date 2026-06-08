# frozen_string_literal: true

module Landfall
  # Pure decision logic for old-username login. Given only plain values (no DB, no
  # Rails), it decides whether to rewrite the login param to a user's current
  # username. The caller does the queries and applies the result.
  #
  # Security invariants encoded here:
  #   * A live owner of the typed username always wins when its password matches.
  #   * We never guess between several imported candidates: exactly one match, or bail.
  module LoginDecision
    # A candidate imported user that previously used the typed username.
    #   current_username - the user's present Discourse username (rewrite target)
    #   legacy_match     - whether the typed password matched this user's legacy hash
    Candidate = Struct.new(:current_username, :legacy_match, keyword_init: true)

    # Returns either :bail or { rewrite_to: <username> }.
    def self.decide(live_present:, live_password_matches:, candidates:)
      return rewrite_to_single(candidates) unless live_present
      return :bail if live_password_matches

      rewrite_to_single(candidates.select(&:legacy_match))
    end

    # Rewrite only when exactly one candidate remains; otherwise refuse.
    def self.rewrite_to_single(candidates)
      case candidates
      in [single]
        { rewrite_to: single.current_username }
      else
        :bail
      end
    end
  end
end
