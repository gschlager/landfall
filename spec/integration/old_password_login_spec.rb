# frozen_string_literal: true

require "rails_helper"

# Tier 2: runs inside a Discourse checkout. Exercises the prepend on
# User#confirm_password? end to end against the database.
RSpec.describe Landfall::UserConfirmPasswordExtension do
  fab!(:user)

  # md5("swordfishtango7") - 15 chars, satisfies the default password policy.
  let(:compliant_password) { "swordfishtango7" }
  let(:compliant_hash) { "c68647a1592dba7f1790a54b7723be69" }
  # md5("password") - 8 chars, fails the default min_password_length.
  let(:weak_password) { "password" }
  let(:weak_hash) { "5f4dcc3b5aa765d61d8327deb882cf99" }

  before do
    SiteSetting.landfall_enabled = true
    SiteSetting.landfall_login_with_old_password_enabled = true
    # Simulate a freshly-imported user with no native password yet.
    user.user_password&.destroy
    user.reload
  end

  def add_legacy(hash)
    Landfall::MigratedPassword.create!(user: user, algorithm: "md5", password_hash: hash)
  end

  it "accepts a policy-compliant legacy password, migrates it, and deletes the legacy row" do
    add_legacy(compliant_hash)

    expect(user.confirm_password?(compliant_password)).to eq(true)
    expect(Landfall::MigratedPassword.exists?(user_id: user.id)).to eq(false)

    user.reload
    expect(user.user_password).to be_present
    expect(user.confirm_password?(compliant_password)).to eq(true) # now via the native path
  end

  it "does not migrate a legacy password that violates the current policy" do
    add_legacy(weak_hash)

    # The password matches, but it is too short for the current policy: it must not be
    # stored, and confirm_password? must not authenticate it here (SessionController
    # routes this user into the reset flow instead).
    expect(user.confirm_password?(weak_password)).to eq(false)
    expect(Landfall::MigratedPassword.exists?(user_id: user.id)).to eq(true)
    expect(user.reload.user_password).to be_nil
  end

  it "rejects a wrong password and keeps the legacy row" do
    add_legacy(compliant_hash)

    expect(user.confirm_password?("wrong")).to eq(false)
    expect(Landfall::MigratedPassword.exists?(user_id: user.id)).to eq(true)
  end

  it "does nothing when the feature is disabled" do
    SiteSetting.landfall_login_with_old_password_enabled = false
    add_legacy(compliant_hash)

    expect(user.confirm_password?(compliant_password)).to eq(false)
    expect(Landfall::MigratedPassword.exists?(user_id: user.id)).to eq(true)
  end

  it "still authenticates users who already have a native password" do
    user.update!(password: "a-strong-native-password")

    expect(user.confirm_password?("a-strong-native-password")).to eq(true)
  end
end
