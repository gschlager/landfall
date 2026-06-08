# frozen_string_literal: true

require_relative "old_username_login"

module Landfall
  # Prepended onto SessionController. Before the normal local-login flow runs, it may
  # rewrite the login param from an old username to the user's current username so the
  # rest of Discourse (rate limiting, 2FA, suspension checks, session creation) is
  # reused unchanged. A failure in the rewrite must never break normal logins.
  module SessionControllerExtension
    def create
      begin
        Landfall::OldUsernameLogin.maybe_rewrite_login!(params)
      rescue StandardError => e
        Rails.logger.warn("Landfall: old-username rewrite skipped (#{e.class}: #{e.message})")
      end

      super
    end
  end
end
