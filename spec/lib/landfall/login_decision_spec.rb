# frozen_string_literal: true

require "spec_helper"
require_relative "../../../lib/landfall/login_decision"

RSpec.describe Landfall::LoginDecision do
  def candidate(username, legacy_match)
    Landfall::LoginDecision::Candidate.new(current_username: username, legacy_match: legacy_match)
  end

  def decide(live_present:, live_password_matches:, candidates:)
    described_class.decide(
      live_present: live_present,
      live_password_matches: live_password_matches,
      candidates: candidates,
    )
  end

  context "when no live user owns the typed username (simple rename)" do
    it "rewrites to the only candidate's current username" do
      result =
        decide(
          live_present: false,
          live_password_matches: false,
          candidates: [candidate("foo2", false)],
        )
      expect(result).to eq(rewrite_to: "foo2")
    end

    it "bails when there are no candidates" do
      expect(decide(live_present: false, live_password_matches: false, candidates: [])).to eq(:bail)
    end

    it "bails when several distinct candidates are ambiguous" do
      candidates = [candidate("foo2", false), candidate("foo3", false)]
      expect(
        decide(live_present: false, live_password_matches: false, candidates: candidates),
      ).to eq(:bail)
    end

    it "ignores legacy_match in this branch (rewrite regardless, super verifies)" do
      result =
        decide(
          live_present: false,
          live_password_matches: false,
          candidates: [candidate("foo2", true)],
        )
      expect(result).to eq(rewrite_to: "foo2")
    end
  end

  context "when a live user owns the typed username (collision)" do
    it "bails so the live owner logs in when their password matches" do
      candidates = [candidate("foo2", true)]
      expect(decide(live_present: true, live_password_matches: true, candidates: candidates)).to eq(
        :bail,
      )
    end

    it "rewrites to the single imported user whose legacy password matches" do
      candidates = [candidate("foo2", true), candidate("foo3", false)]
      expect(
        decide(live_present: true, live_password_matches: false, candidates: candidates),
      ).to eq(rewrite_to: "foo2")
    end

    it "bails when no imported candidate's legacy password matches" do
      candidates = [candidate("foo2", false), candidate("foo3", false)]
      expect(
        decide(live_present: true, live_password_matches: false, candidates: candidates),
      ).to eq(:bail)
    end

    it "bails when more than one imported candidate matches (ambiguous)" do
      candidates = [candidate("foo2", true), candidate("foo3", true)]
      expect(
        decide(live_present: true, live_password_matches: false, candidates: candidates),
      ).to eq(:bail)
    end
  end
end
