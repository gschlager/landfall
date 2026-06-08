# Testing & quality standard

Landfall targets **100% test coverage** plus **mutation testing** with
[mutant](https://github.com/mbj/mutant). Line coverage alone is not enough for
security-sensitive auth code — mutation testing is what proves a flipped `>=`/`>`,
a dropped `secure_compare`, or a missed branch is actually caught by a spec.

## Two tiers

### Tier 1 — pure logic (mutant-gated, 100% mutation kill)

All real decision logic lives in pure, Rails-free POROs so mutant can load and
mutate them fast and deterministically **without booting Discourse**:

- `Landfall::Hashers::{MD5,SHA1,SHA256,SHA512,Bcrypt,Phpass,VBulletin,IPB,SMF,
  Drupal7,Joomla,Crypt}` — each a pure `match?(password, hash, salt:, **meta)`.
- `Landfall::LegacyPasswordVerifier` — pure dispatch over the hashers
  (uses `ActiveSupport::SecurityUtils.secure_compare` for digest comparisons).
- `Landfall::LoginDecision` — pure: given `(live_password_matches:, candidates:)`
  (plain structs carrying a precomputed `legacy_match` boolean), returns `:bail` or
  `{ rewrite_to: <username> }`. All the rename / collision (Foo·Foo1·Foo2) branch
  logic lives here.

These have pure unit specs (no `rails_helper`, just `require` the file under test).
**Gate:** mutant must report 100% mutation coverage for this namespace.

### Tier 2 — Discourse glue (integration specs + SimpleCov, excluded from mutant)

Thin adapters that call `super`, hit ActiveRecord, and mutate params — impractical
and low-value to mutation-test:

- `Landfall::UserConfirmPasswordExtension#confirm_password?` (prepend on `User`).
- `Landfall::SessionControllerExtension#create` (prepend on `SessionController`).
- `Landfall::OldUsernameLogin` (AR queries → build `candidates` → call
  `LoginDecision` → rewrite `params[:login]`).

These are covered by request/integration specs that boot Discourse and exercise the
real login flow (old-password login, simple rename, the collision-by-password
scenario, ambiguous-refusal, feature flags). **Gate:** SimpleCov 100% line + branch
coverage; these classes are listed in mutant's `ignore`/excluded subjects.

## Tooling

- `Gemfile` (dev/test group): `mutant`, `mutant-rspec`, `simplecov`.
- `config/mutant.yml`: `integration: { name: rspec }`, `requires:` the pure files,
  `matcher.subjects:` = `Landfall::Hashers*`, `Landfall::LegacyPasswordVerifier*`,
  `Landfall::LoginDecision*`. Run: `bundle exec mutant run --usage opensource`
  (free — the repo is public and MIT). Use `--since main` for fast incremental
  runs locally.
- SimpleCov configured in the spec setup with `minimum_coverage line: 100,
  branch: 100`.
- CI (`.github/workflows`): one job runs the full RSpec suite under SimpleCov; a
  second runs `mutant run --usage opensource` over the pure-logic namespace. Both
  must be green to merge.

## Why this split

Mutant rewards pure, independently-loadable code and fights monkeypatch glue
(`super`, ActiveRecord, full Rails boot). Concentrating every real branch in
Tier-1 POROs means the security-critical correctness is exhaustively proven by
mutation testing, while the unavoidable Discourse-integration shim is kept trivial
and verified end-to-end by integration specs.
