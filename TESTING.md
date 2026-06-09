# Testing & quality standard

Landfall targets **mutation testing** with [mutant](https://github.com/mbj/mutant) on
its security-sensitive auth logic. Line coverage alone is not enough for code that
verifies passwords — mutation testing is what proves a flipped `>=`/`>`, a dropped
guard, or a missed branch is actually caught by a spec.

The day-to-day workflow for running mutant and resolving alive mutations lives in the
`.claude/skills/mutant` skill (adapted from Markbridge's, by dkubb).

## Two tiers

### Tier 1 — pure logic (mutant-gated, **100% mutation kill**)

All real decision logic lives in pure, Rails-free POROs so mutant can load and mutate
them fast and deterministically **without booting Discourse**. Current status:
**435 mutations, 0 alive, 100%.**

- `Landfall::Hashers::{MD5,SHA1,SHA256,SHA512,BCrypt,VBulletin,IPB,SMF,Joomla,Crypt}`
  — each a pure `match?(password:, hash:, salt:, metadata:)`.
- `Landfall::LegacyPasswordVerifier` — pure dispatch over the hashers. Digest
  comparison uses plain `==`: the inputs are cryptographic digests of the
  attacker-supplied password vs. a stored digest, and preimage resistance means the
  timing of `==` leaks nothing exploitable, so a constant-time compare buys no
  security here while it would add equivalent mutants.
- `Landfall::LoginDecision` — pure: given `(live_present:, live_password_matches:,
  candidates:)`, returns `:bail` or `{ rewrite_to: <username> }`. All the rename /
  collision (Foo·Foo1·Foo2) branch logic lives here.

Specs: `spec/lib/landfall/**` (no `rails_helper`; each requires only the file under
test). Run them standalone with `rspec` (the repo `.rspec` scopes the default run to
`spec/lib`).

#### Excluded from the gate: `Landfall::Hashers::Phpass`

phpass (WordPress / phpBB3) is implemented and **cross-validated against passlib's
authoritative vectors** in the verifier spec, but its bit-level encoder is excluded
from the mutation gate (`matcher.ignore` in `config/mutant.yml`). Two of its mutants
are irreducible: the round upper bound (`> 30`) would need a 2³⁰-iteration fixture to
kill, and the base64 boundary is an equivalent mutant for the fixed 16-byte MD5 input.

### Tier 2 — Discourse glue (integration specs, **not** mutated)

Thin adapters that call `super`, hit ActiveRecord, and mutate params — impractical and
low-value to mutation-test:

- `Landfall::UserConfirmPasswordExtension#confirm_password?` (prepend on `User`).
- `Landfall::SessionControllerExtension#create` (prepend on `SessionController`).
- `Landfall::OldUsernameLogin` (AR queries → build `candidates` → call `LoginDecision`
  → rewrite `params[:login]`).
- `Landfall::PasswordPolicy` (validates a throwaway `UserPassword`) and
  `Landfall::LegacyLogin` (classifies a login against the stored record). The reset
  itself is delegated to core's `SessionController#enqueue_password_reset_for_user`.

Covered by `spec/integration/**`, which `require "rails_helper"` and run inside a
Discourse checkout (`bin/rspec plugins/landfall/spec/integration`). They exercise the
real flow: legacy-password login + migration-on-success, simple rename, the
collision-by-password scenario, ambiguous-refusal, and the feature flags.

## Tooling

- `Gemfile` (Tier-1 standalone deps): `bcrypt`, `rspec`, `simplecov`, `mutant`,
  `mutant-rspec`.
- `config/mutant.yml` holds the subjects, requires, includes, and the Phpass ignore,
  so the command is just `bundle exec bin/mutant run`.
- `bin/mutant` is a tiny wrapper that loads mutant's real entrypoint (Bundler does not
  expose mutant's binstub). Use `--since main` for fast incremental local runs.
- mutant runs under `usage: opensource` (free — the repo is public and MIT).

## CI

`.github/workflows/ci.yml` runs the Tier-1 job: the pure RSpec suite, then
`bundle exec bin/mutant run` (the 100% gate). Both must be green to merge. The Tier-2
integration specs run inside Discourse's own plugin CI.

## Why this split

Mutant rewards pure, independently-loadable code and fights monkeypatch glue (`super`,
ActiveRecord, full Rails boot). Concentrating every real branch in Tier-1 POROs means
the security-critical correctness is exhaustively proven by mutation testing, while
the unavoidable Discourse-integration shim is kept trivial and verified end-to-end by
integration specs.
