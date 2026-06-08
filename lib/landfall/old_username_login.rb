# frozen_string_literal: true

require_relative "legacy_password_verifier"
require_relative "login_decision"

module Landfall
  # Thin ActiveRecord boundary for old-username login. It gathers the plain values
  # the pure LoginDecision needs, then applies the decision by rewriting params.
  # All branch logic lives in LoginDecision (which is mutation-tested); this object
  # is covered by the Discourse-integration specs.
  module OldUsernameLogin
    def self.maybe_rewrite_login!(params)
      return unless SiteSetting.landfall_login_with_old_username_enabled

      login = params[:login].to_s
      return if login.blank? || login.include?("@")

      normalized = User.normalize_username(login)
      user_ids = OldUsername.where(username_lower: normalized).distinct.pluck(:user_id)
      return if user_ids.empty?

      live = User.find_by(username_lower: normalized)
      password = params[:password].to_s

      decision =
        LoginDecision.decide(
          live_present: live.present?,
          live_password_matches: live.present? && live.confirm_password?(password),
          candidates: candidates_for(user_ids, exclude: live, password: password),
        )

      params[:login] = decision[:rewrite_to] if decision.is_a?(Hash)
    end

    def self.candidates_for(user_ids, exclude:, password:)
      scope = User.where(id: user_ids)
      scope = scope.where.not(id: exclude.id) if exclude
      scope.map do |user|
        LoginDecision::Candidate.new(
          current_username: user.username,
          legacy_match: legacy_match?(user, password),
        )
      end
    end

    def self.legacy_match?(user, password)
      migrated = user.landfall_migrated_password
      return false if migrated.blank?

      LegacyPasswordVerifier.matches?(
        algorithm: migrated.algorithm,
        hash: migrated.password_hash,
        password: password,
        salt: migrated.salt,
        metadata: migrated.metadata,
      )
    end
  end
end
