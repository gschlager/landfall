# frozen_string_literal: true

require "rails_helper"

# Tier 2: runs inside a Discourse checkout. Exercises the old-username param rewrite
# (the AR boundary) against the database, including the live-username collision case.
RSpec.describe Landfall::OldUsernameLogin do
  before do
    SiteSetting.landfall_enabled = true
    SiteSetting.landfall_login_with_old_username_enabled = true
  end

  # md5("password")
  let(:md5_hash) { "5f4dcc3b5aa765d61d8327deb882cf99" }

  def rewrite(login:, password: "x")
    params = ActionController::Parameters.new(login: login, password: password)
    described_class.maybe_rewrite_login!(params)
    params[:login]
  end

  def add_old_username(user, name)
    Landfall::OldUsername.create!(user: user, username: name)
  end

  def add_legacy_password(user, hash)
    Landfall::MigratedPassword.create!(user: user, algorithm: "md5", password_hash: hash)
  end

  context "with a simple rename (no live collision)" do
    it "rewrites the old username to the user's current username" do
      user = Fabricate(:user, username: "foo2")
      add_old_username(user, "foo")

      expect(rewrite(login: "foo")).to eq("foo2")
    end

    it "leaves the login untouched when the old username is ambiguous" do
      add_old_username(Fabricate(:user, username: "foo2"), "foo")
      add_old_username(Fabricate(:user, username: "foo3"), "foo")

      expect(rewrite(login: "foo")).to eq("foo")
    end

    it "does nothing when the feature is disabled" do
      SiteSetting.landfall_login_with_old_username_enabled = false
      add_old_username(Fabricate(:user, username: "foo2"), "foo")

      expect(rewrite(login: "foo")).to eq("foo")
    end

    it "ignores email logins" do
      add_old_username(Fabricate(:user, username: "foo2"), "foo")

      expect(rewrite(login: "foo@example.com")).to eq("foo@example.com")
    end
  end

  context "with a live-username collision (Foo / Foo1 / Foo2)" do
    fab!(:native) { Fabricate(:user, username: "foo", password: "native-password") }
    fab!(:imported) { Fabricate(:user, username: "foo2") }

    before do
      add_old_username(imported, "foo")
      add_legacy_password(imported, md5_hash) # imported user's old password was "password"
    end

    it "keeps the live owner when their password matches" do
      expect(rewrite(login: "foo", password: "native-password")).to eq("foo")
    end

    it "rewrites to the imported user when only their legacy password matches" do
      expect(rewrite(login: "foo", password: "password")).to eq("foo2")
    end

    it "leaves the login untouched when neither password matches" do
      expect(rewrite(login: "foo", password: "neither")).to eq("foo")
    end

    it "refuses when two imported users both match the password (ambiguous)" do
      other = Fabricate(:user, username: "foo3")
      add_old_username(other, "foo")
      add_legacy_password(other, md5_hash)

      expect(rewrite(login: "foo", password: "password")).to eq("foo")
    end
  end
end
