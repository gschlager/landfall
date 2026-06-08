# Landfall — Ideas & Roadmap

**Landfall** is a migration-companion plugin for Discourse: it helps admins and
developers *before*, *during*, and *after* importing one or more communities into
Discourse, and helps members feel at home once they arrive. It is a sibling to the
MIT [`discourse/markbridge`](https://github.com/discourse/markbridge) markup-conversion gem.

This file is an idea backlog, not a commitment. The two confirmed v1 features are at
the bottom under **"v1 scope"**.

---

## Admin / developer

### Before — planning & rehearsal
- **Source-data linter / health report** — scan the export for encoding problems,
  malformed BBCode, oversized/missing attachments, orphaned posts, duplicate or
  role/spam-trap emails. Surface the pain before the run, not after.
- **Feature-gap report** — flag old-forum constructs with no clean Discourse
  equivalent (signatures, polls, custom profile fields, reputation systems) and how
  each will be mapped or dropped.
- **Mapping-as-code** — versioned YAML for board→category, old roles→groups/
  permissions, so a migration is reproducible and reviewable in a PR.
- **Email deliverability pre-check** — validate/clean the address list and detect
  role accounts before any "claim your account" campaign, to protect sending reputation.
- **Rehearsal sandbox** — spin a staging clone seeded with a representative sample
  for a full dry run.

### During — execution
- **Resumable, idempotent import with checkpoints** — crash on row 4M, resume from
  4M, never double-create.
- **Live dashboard + error-triage queue** — per-entity progress/ETA; failed rows land
  in a retryable queue with the reason, instead of scrolling console logs.
- **Dry-run diff** — "what would change if I re-ran this?" before committing a delta.
- **Throttle + completion webhooks** — rate-limit to avoid hammering prod; ping
  Slack/email on finish or failure.

### After — cutover, validation, cleanup
- ⭐ **Reconciliation report** — source counts vs Discourse counts per entity, with a
  drill-down list of discrepancies. The best "did we lose anything?" safety net.
- **Old↔new ID mapping lookup/API** — invaluable for debugging, redirects, and
  external integrations long after the run.
- ⭐ **Attachment rehoming** — pull still-hotlinked images/files from the *old* server
  into Discourse uploads *before that server is decommissioned*, with an
  unreachable-asset report. A ticking clock most migrations forget.
- **Trust-level & badge seeding from legacy activity** — map old post counts/tenure/
  reputation to TL2/TL3 and grant "Veteran since 2009"-style badges, so long-time
  members don't arrive as brand-new TL0 accounts.
- **Duplicate-account detection + guided merge** — same person, multiple old logins.
- ⭐ **Audit log of legacy logins** — record who authenticated via old-password /
  old-username and when. Complements the v1 login features and the auto-expiry dashboard.
- **Namespaced rollback** — drop everything tagged with a given import batch id to
  retry cleanly.
- **Legacy-credential auto-expiry + admin dashboard** — scheduled job purges stored
  legacy hashes / old usernames after a configurable grace period; admin panel shows
  remaining counts + account-claim stats. (The v1 tables already carry `created_at`.)
- **In-admin Markbridge playground** — admin route using the MIT `markbridge` gem to
  paste source markup and preview Discourse Markdown/AST (pre-import calibration +
  ad-hoc conversion). *Conditional:* "bulk re-cook of imported posts" is only feasible
  if the original source markup was preserved at import; otherwise out of scope.

---

## Community member — after the move
- ⭐ **Magic-link account claim** — find your account by old username *or* old email,
  get a one-click claim link. Sidesteps username collisions (email is unique) and
  pairs with old-password login as the two on-ramps.
- **History-aware welcome** — a first-login tour that references their real past: join
  date, post count, top topics — "welcome back," not "welcome."
- **Username-change notice** — "you were renamed X → Y," with a one-tap request for a
  different name.
- **Restore my prefs** — re-subscribe watched categories, bookmarks, locale, timezone
  from old settings.
- **"Was this converted correctly?"** — inline report on imported posts that feeds an
  admin review queue (the realistic version of fixing markup — human-flagged, not
  blind bulk re-cook).
- **Continuity surfaces** — preserved permalinks to old posts/profile (core
  Permalinks), badge/reputation continuity on the profile, optional avatar import /
  Gravatar fallback.
- **Claim-your-account onboarding** — member-facing landing page (find account by old
  username/email) + first-login UX (set new password, confirm email).

---

## The reusable foundation

Three assets power most of the above:
1. The **old↔new ID-mapping table**.
2. **Preserved original metadata** (old username, join date, activity, source markup).
3. The **Markbridge pipeline** for markup conversion.

The v1 login features are the thin end of "identity continuity"; audit-log and
magic-link claim sit right next to them as the most natural next steps.

---

## v1 scope (what the first PR builds)

Only the two login features — see the design plan for details:
1. **Login with the old password** — verify the entered password against a stored
   legacy hash (md5/sha1/sha256/sha512/bcrypt/phpass/vBulletin/IPB/
   SMF/Drupal7/Joomla/crypt), then re-hash to Discourse's native `pbkdf2` and delete
   the legacy hash. Stored in a plugin-owned table, never in a serializer.
2. **Login with the old username** — users renamed during import can log in with their
   previous name. Handled at the controller layer by rewriting the login param, which
   also disambiguates live-username collisions by password (the Foo / Foo1 / Foo2 case).

Dropped: a 301 redirect map — Discourse core **Permalinks** already cover this.
