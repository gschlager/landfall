# frozen_string_literal: true

require "rails_helper"

RSpec.describe Landfall::PasswordPolicy do
  fab!(:user)

  it "accepts a password that satisfies the current policy" do
    expect(described_class.compliant?(user, "swordfishtango7")).to eq(true)
  end

  it "rejects a password shorter than min_password_length" do
    SiteSetting.min_password_length = 10
    expect(described_class.compliant?(user, "short")).to eq(false)
  end

  it "rejects a blocked common password" do
    SiteSetting.block_common_passwords = true
    expect(described_class.compliant?(user, "password")).to eq(false)
  end

  it "does not persist anything" do
    expect { described_class.compliant?(user, "swordfishtango7") }.not_to change {
      user.reload.user_password
    }
  end
end

RSpec.describe Landfall::LegacyLogin do
  fab!(:user)

  # md5("swordfishtango7") and md5("password")
  let(:compliant_hash) { "c68647a1592dba7f1790a54b7723be69" }
  let(:weak_hash) { "5f4dcc3b5aa765d61d8327deb882cf99" }

  before do
    SiteSetting.landfall_enabled = true
    SiteSetting.landfall_login_with_old_password_enabled = true
    SiteSetting.landfall_force_password_reset_enabled = true
  end

  def add_legacy(hash)
    Landfall::MigratedPassword.create!(user: user, algorithm: "md5", password_hash: hash)
  end

  it "returns :none when the plugin is disabled" do
    SiteSetting.landfall_enabled = false
    add_legacy(compliant_hash)
    expect(described_class.classify(user, "swordfishtango7")).to eq(:none)
  end

  it "returns :none when there is no legacy password" do
    expect(described_class.classify(user, "swordfishtango7")).to eq(:none)
  end

  it "returns :none when the password does not match the legacy hash" do
    add_legacy(compliant_hash)
    expect(described_class.classify(user, "wrong")).to eq(:none)
  end

  it "returns :none when the feature is disabled" do
    SiteSetting.landfall_login_with_old_password_enabled = false
    add_legacy(compliant_hash)
    expect(described_class.classify(user, "swordfishtango7")).to eq(:none)
  end

  it "returns :compliant when the matched password satisfies the policy" do
    add_legacy(compliant_hash)
    expect(described_class.classify(user, "swordfishtango7")).to eq(:compliant)
  end

  it "returns :non_compliant when the matched password violates the policy" do
    add_legacy(weak_hash)
    expect(described_class.classify(user, "password")).to eq(:non_compliant)
  end

  context "with a reset-required marker (no importable password)" do
    before { Landfall::MigratedPassword.create!(user: user, reset_required: true) }

    it "returns :reset_required regardless of the password typed" do
      expect(described_class.classify(user, "anything")).to eq(:reset_required)
    end

    it "returns :none when the force-reset feature is disabled" do
      SiteSetting.landfall_force_password_reset_enabled = false
      expect(described_class.classify(user, "anything")).to eq(:none)
    end
  end
end
