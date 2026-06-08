---
name: mutant
description: Run mutant, read mutation reports, fix alive mutations, and verify 100% coverage on Landfall's pure-logic namespace. Use when running mutation testing or responding to alive mutations.
compatibility: Unified agent skills CLI
metadata:
  author: Gerhard Schlager
  adapted_from: discourse/markbridge .claude/skills/mutant (by dkubb)
  version: "2026-06-v1"
triggers:
  - "mutation testing"
  - "mutant"
  - "alive mutation"
  - "mutation coverage"
---

# Mutant (Landfall)

## When to Activate

- The user asks to run mutation testing or verify mutation coverage.
- There are alive mutations to fix.
- You changed code under `lib/landfall/` that the mutation gate covers.

## When Not to Use

- The task does not involve mutation testing.
- The change is only in the Discourse glue (Tier 2 — see below), which is not gated.

## Landfall's two tiers

Mutation testing here gates **only the pure, Rails-free logic** (Tier 1). The
Discourse glue (Tier 2) is verified by integration specs, not mutated. See
`TESTING.md`.

- **Gated (Tier 1):** `Landfall::Hashers::*` (except `Phpass`), `LegacyPasswordVerifier`,
  `LoginDecision`. Must stay at **100% kill**.
- **Not gated (Tier 2):** `UserConfirmPasswordExtension`, `SessionControllerExtension`,
  `OldUsernameLogin`, the AR models. These call `super`/ActiveRecord and only run
  under a booted Discourse.
- **Excluded with rationale:** `Landfall::Hashers::Phpass*` — its bit-level encoder
  has irreducible mutants (the round upper bound needs a 2**30-iteration fixture; the
  base64 boundary is equivalent for fixed 16-byte MD5 input). It is cross-validated
  against passlib's authoritative vectors instead. Keep it in `matcher.ignore`.

## How to run

The subjects, requires, includes and ignores live in `config/mutant.yml`, so the
canonical command is just:

```bash
bundle exec mutant run            # full gate, reads config/mutant.yml
bundle exec mutant run --fail-fast # stop at the first alive mutation
```

If `bundle exec mutant` reports "command not found" (Bundler doesn't always expose
mutant's binstub), invoke the entrypoint directly:

```bash
bundle exec ruby "$(bundle exec ruby -e 'print Gem.bin_path("mutant","mutant-ruby")')" run
```

The fast pure-logic RSpec suite (no Discourse) is `rspec spec/lib/landfall` and must be
green before you trust a mutation run.

## Reading output

An alive mutation looks like:

```text
evil:Landfall::LoginDecision.decide:lib/landfall/login_decision.rb:18:eded4
@@ -1,3 +1,3 @@
 def self.decide(...)
-  matched.length != 1
+  !matched.length.eql?(1)
 end
```

`evil` = no test killed it. The console truncates to one example per subject and
prints `(N more alive mutation(s))`; fix what you see, re-run, repeat.

## Decision framework

For each alive mutation, exactly one of:

- **Killable → add a test.** Write the smallest example that fails against the mutated
  behaviour (the boundary case, the nil input, the omitted kwarg). Tests come first.
- **Killable → simplify (least power).** If simpler code passes every test, the
  original was doing work nothing relies on — adopt the mutation. But simplification
  must never paper over a missing test; add the test first if there's a real gap.
- **Equivalent → ignore.** If no test can ever distinguish it, add the subject to
  `matcher.ignore` in `config/mutant.yml` with a comment explaining *why*. Do this
  sparingly and only after proving equivalence.

## Patterns that eliminate equivalent mutants (learned in this repo)

Prefer refactoring code into a mutant-friendly shape over growing the ignore list:

- **Singleton methods, not `module_function`.** `module_function` makes a private
  *instance* copy and a *singleton* copy; mutant mutates one while specs call the
  other, so everything survives. Use `def self.foo`.
- **"Exactly one" via pattern match.** `case xs in [single]` instead of
  `xs.length != 1` + `xs.first`. Avoids the `!= 1`↔`!eql?(1)` and `.first`↔`.last`
  (single-element) equivalents.
- **No dead default kwargs.** A `salt: nil` default that every caller overrides is a
  surviving mutant (`salt:` required is "equivalent"). Make internal params required;
  keep defaults only on the public entrypoint and add a spec that omits them.
- **Split compound guards.** `return false if a || b` makes `||`↔`&&` equivalent when
  both paths yield the same result. Two separate `return false if` lines are each
  killable.
- **Make stray constant references lethal.** `::Gem`↔`Gem` is equivalent when the bare
  name resolves to the same top-level constant. Naming the wrapper module after the
  gem (e.g. `Hashers::BCrypt`) makes a non-rooted `BCrypt` resolve to the wrapper
  (NameError) — killing the mutation instead of ignoring it.
- **`.to_s` guards are killable with nil.** `hash.to_s.empty?` survives `.to_s`
  removal unless a spec passes `nil`.

## Commit hygiene

- One subject per commit; never mix a test change and the source change it covers in
  the same commit.
- The commit message says *why* (e.g. "kill round-boundary mutants with rounds=7
  fixture", "ignore equivalent `::BCrypt` resolution").
- Re-run `bundle exec mutant run` and confirm `Coverage: 100.00%` before finishing.

## Outputs (fixed order)

1. Mutation results: alive count and coverage percentage.
2. The action taken for each alive mutation (test added / simplified / ignored + why).
