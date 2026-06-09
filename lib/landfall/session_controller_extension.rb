# frozen_string_literal: true

require_relative "old_username_login"
require_relative "legacy_login"

module Landfall
  # Prepended onto SessionController. Before the normal local-login flow runs it:
  #   1. rewrites the login param from an old username to the current one, and
  #   2. intercepts members who must set a new password (a matched-but-non-compliant
  #      legacy password, or no usable imported password): rather than storing anything
  #      or reimplementing a reset, it asks Discourse to send its own password-reset
  #      email (SessionController#enqueue_password_reset_for_user) and bounces the login
  #      with a distinct reason + message.
  # A compliant legacy password is left for User#confirm_password? to migrate during the
  # normal login. A failure in this interception must never break normal logins.
  module SessionControllerExtension
    FORCED_RESET_STATES = %i[non_compliant reset_required].freeze

    def create
      payload = nil

      begin
        Landfall::OldUsernameLogin.maybe_rewrite_login!(params)
        payload = forced_reset_payload
      rescue StandardError => e
        Rails.logger.warn("Landfall: login interception skipped (#{e.class}: #{e.message})")
      end

      return render(json: payload) if payload

      super
    end

    private

    def forced_reset_payload
      login = normalized_login_param
      return if login.blank?

      user = User.find_by_username_or_email(login)
      # Skip once the user has a real password (e.g. after completing the reset).
      return if user.blank? || user.has_password?

      status = Landfall::LegacyLogin.classify(user, params[:password].to_s)
      return if FORCED_RESET_STATES.exclude?(status)

      # Reuse Discourse's own reset flow (token, rate limit, mailer) verbatim.
      begin
        enqueue_password_reset_for_user(user)
      rescue RateLimiter::LimitExceeded
        # Already emailed recently; still show the reset message.
      end

      { error: I18n.t("landfall.must_reset_password"), reason: "must_reset_password" }
    end
  end
end
