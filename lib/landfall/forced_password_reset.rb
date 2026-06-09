# frozen_string_literal: true

module Landfall
  # Routes a user into Discourse's password-reset flow by sending them the
  # "set/reset your password" email (rate-limited). For passwordless accounts the
  # mailer automatically uses the "set password" template.
  #
  # This is the single building block for "this member must choose a new password".
  # Today it is used when a matched legacy password violates the current policy; it is
  # intended to be reused for imported users whose password could not be migrated at
  # all, so they too can be guided to set one.
  module ForcedPasswordReset
    EMAILS_PER_DAY = 3

    def self.call(user)
      RateLimiter.new(
        nil,
        "landfall-force-reset-#{user.username}",
        EMAILS_PER_DAY,
        1.day,
      ).performed!

      email_token =
        user.email_tokens.create!(email: user.email, scope: EmailToken.scopes[:password_reset])

      Jobs.enqueue(
        :critical_user_email,
        type: "forgot_password",
        user_id: user.id,
        email_token: email_token.token,
      )
    rescue RateLimiter::LimitExceeded
      # Already emailed recently; the user still sees the "check your email" message.
    end
  end
end
