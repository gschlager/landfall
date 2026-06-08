# frozen_string_literal: true

require "rails_helper"

# Tier 2: runs inside a Discourse checkout (uses rails_helper). Exercises the
# prepend on User#confirm_password? end to end against the database.
RSpec.describe Landfall::UserConfirmPasswordExtension do
  fab!(:user)

  # md5("password")
  let(:md5_hash) { "5f4dcc3b5aa765d61d8327deb882cf99" }

  before do
    SiteSetting.landfall_enabled = true
    SiteSetting.landfall_login_with_old_password_enabled = true
    # Simulate a freshly-imported user with no native password yet.
    user.user_password&.destroy
    user.reload
  end

  def add_legacy(algorithm:, hash:, salt: nil, metadata: nil)
    Landfall::MigratedPassword.create!(
      user: user,
      algorithm: algorithm,
      password_hash: hash,
      salt: salt,
      metadata: metadata,
    )
  end

  it "accepts the legacy password, migrates to native, and deletes the legacy row" do
    add_legacy(algorithm: "md5", hash: md5_hash)

    expect(user.confirm_password?("password")).to eq(true)
    expect(Landfall::MigratedPassword.exists?(user_id: user.id)).to eq(false)

    user.reload
    expect(user.user_password).to be_present
    expect(user.confirm_password?("password")).to eq(true) # now via the native path
  end

  it "rejects a wrong password and keeps the legacy row" do
    add_legacy(algorithm: "md5", hash: md5_hash)

    expect(user.confirm_password?("wrong")).to eq(false)
    expect(Landfall::MigratedPassword.exists?(user_id: user.id)).to eq(true)
  end

  it "does nothing when the feature is disabled" do
    SiteSetting.landfall_login_with_old_password_enabled = false
    add_legacy(algorithm: "md5", hash: md5_hash)

    expect(user.confirm_password?("password")).to eq(false)
    expect(Landfall::MigratedPassword.exists?(user_id: user.id)).to eq(true)
  end

  it "still authenticates users who already have a native password" do
    user.update!(password: "a-strong-native-password")

    expect(user.confirm_password?("a-strong-native-password")).to eq(true)
  end
end
