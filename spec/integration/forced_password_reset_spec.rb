# frozen_string_literal: true

require "rails_helper"

# The user-facing behaviour: a matched-but-non-compliant legacy password must not be
# stored; instead the login is bounced and Discourse's own reset email is sent.
RSpec.describe "Landfall forced password reset on login", type: :request do
  fab!(:user)

  # md5("password") - matches but is too short for the default policy.
  let(:weak_hash) { "5f4dcc3b5aa765d61d8327deb882cf99" }

  before do
    SiteSetting.landfall_enabled = true
    SiteSetting.landfall_login_with_old_password_enabled = true
    user.user_password&.destroy
    user.reload
    Landfall::MigratedPassword.create!(user: user, algorithm: "md5", password_hash: weak_hash)
  end

  it "bounces the login, keeps the legacy hash unstored, and emails a reset link" do
    post "/session.json", params: { login: user.username, password: "password" }

    expect(response.status).to eq(200)
    expect(response.parsed_body["reason"]).to eq("must_reset_password")
    # The weak password was not migrated to a native password...
    expect(user.reload.user_password).to be_nil
    # ...the legacy row is kept so the user can re-trigger the email...
    expect(Landfall::MigratedPassword.exists?(user_id: user.id)).to eq(true)
    # ...and a password-reset token was created.
    expect(user.email_tokens.where(scope: EmailToken.scopes[:password_reset]).exists?).to eq(true)
  end

  it "does not interfere with a wrong password" do
    post "/session.json", params: { login: user.username, password: "definitely-wrong" }

    expect(response.parsed_body["reason"]).to be_nil
    expect(response.parsed_body["error"]).to be_present
    expect(user.email_tokens.where(scope: EmailToken.scopes[:password_reset]).exists?).to eq(false)
  end
end

# Imported users with no usable password (the import couldn't bring one over) are
# flagged and routed to set a password the moment they try to sign in.
RSpec.describe "Landfall forced reset for passwordless imported users", type: :request do
  fab!(:user)

  before do
    SiteSetting.landfall_enabled = true
    SiteSetting.landfall_force_password_reset_enabled = true
    user.user_password&.destroy
    user.reload
    Landfall::MigratedPassword.create!(user: user, reset_required: true)
  end

  it "bounces any login attempt and emails a set-password link" do
    post "/session.json", params: { login: user.username, password: "whatever-they-typed" }

    expect(response.parsed_body["reason"]).to eq("must_reset_password")
    expect(user.email_tokens.where(scope: EmailToken.scopes[:password_reset]).exists?).to eq(true)
  end

  it "stops bouncing once the user has set a password" do
    user.update!(password: "swordfishtango7")

    post "/session.json", params: { login: user.username, password: "swordfishtango7" }

    expect(response.parsed_body["reason"]).to be_nil
    expect(response.parsed_body["error"]).to be_nil
  end
end
