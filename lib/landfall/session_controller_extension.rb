# frozen_string_literal: true

require_relative "old_username_login"
require_relative "legacy_login"
require_relative "forced_password_reset"

module Landfall
  # Prepended onto SessionController. Before the normal local-login flow runs it:
  #   1. rewrites the login param from an old username to the current one, and
  #   2. intercepts a matched-but-non-compliant legacy password: rather than storing a
  #      password that violates the current policy, it emails the user a set-password
  #      link and bounces the login with a distinct reason.
  # A compliant legacy password is left for User#confirm_password? to migrate during
  # the normal login. A failure in this interception must never break normal logins.
  module SessionControllerExtension
    def create
      payload = nil

      begin
        Landfall::OldUsernameLogin.maybe_rewrite_login!(params)
        payload = landfall_forced_reset_payload
      rescue StandardError => e
        Rails.logger.warn("Landfall: login interception skipped (#{e.class}: #{e.message})")
      end

      return render(json: payload) if payload

      super
    end

    private

    FORCED_RESET_STATES = %i[non_compliant reset_required].freeze

    def landfall_forced_reset_payload
      login = normalized_login_param
      return if login.blank?

      user = User.find_by_username_or_email(login)
      # Skip once the user has a real password (e.g. after completing the reset).
      return if user.blank? || user.has_password?

      status = Landfall::LegacyLogin.classify(user, params[:password].to_s)
      return if FORCED_RESET_STATES.exclude?(status)

      Landfall::ForcedPasswordReset.call(user)
      { error: I18n.t("landfall.must_reset_password"), reason: "must_reset_password" }
    end
  end
end
