# 🌊 Landfall

> *Your community just sailed to a new home. Landfall makes sure everyone gets ashore.*

**Landfall** is a migration-companion plugin for [Discourse](https://www.discourse.org).
It smooths the cutover when you import one or more communities into Discourse — and helps
members feel at home the moment they arrive. The login features below are just the *first
step*; the [roadmap](IDEAS.md) goes a lot further.

Sibling to the MIT [`discourse/markbridge`](https://github.com/discourse/markbridge)
markup-conversion gem, and held to the same strict quality bar — see [`TESTING.md`](TESTING.md).

## ✨ What you get

- 🔑 **Log in with the old password** — members sign in with the password from their
  *old* forum. Landfall checks it against the stored legacy hash, and on a match *quietly*
  re-hashes it to Discourse's native algorithm and **shreds the legacy hash**. Used exactly
  once, then gone. *11 hash formats supported.*
- 📧 **Automatic set-password email** — no usable password to import? Instead of a cryptic
  *"incorrect password"*, the member gets a friendly set-password link the first time they
  try to sign in. No day-one mass reset, no flood of confused support emails.
- 👤 **Log in with the old username** — renamed by Discourse's de-duplication during the
  import? Members can still sign in under their *old* name. Collisions are settled by
  password — **never guessed** — so nobody's account gets hijacked.

---

## 🔍 How it works

### 🔑 Log in with the old password

Imported users almost always land with **no Discourse password** — which means a day-one
reset for *everyone*. Ugh.

Landfall fixes that. When Discourse's native check comes up empty, it verifies the typed
password against the stored legacy hash. Match? It re-hashes to Discourse's native
algorithm and **deletes the legacy hash on the spot** — touched exactly once, then never
again.

It speaks the dialects of `md5`, `sha1`, `sha256`, `sha512`, `bcrypt`, `vbulletin`, `ipb`,
`smf`, `joomla`, `crypt`, and `phpass` (WordPress / phpBB3).

One guardrail: a matched password is only kept if it **clears Discourse's current password
policy** (length, blocklist, and friends). Correct but non-compliant? It's *never* stored —
the member is handed straight to the reset flow below.

### 📧 Set a new password when there's no usable one

Some members simply can't keep their old password — it didn't survive the import, or it no
longer meets the policy. The catch: they have *no idea* anything's wrong.

So when they try to sign in, Landfall emails them a set-password link and shows a clear,
human message — not a blunt *"incorrect password"*. It rides on Discourse's own reset-email
flow (and the *"set password"* template for passwordless accounts), and bows out the moment
they've set one.

### 👤 Log in with the old username

Discourse's username rules and de-duplication love to **rename** people during an import.
Landfall lets a renamed member sign in under their *old* name: it swaps the typed name for
their current username *before* the normal login runs, so rate limiting, 2FA, and sessions
keep working exactly as they always do.

The interesting bit is **collisions**. Say the imported community had a `Foo`, but the
destination already had a *different* `Foo` — so the newcomer became `Foo2`. Type `Foo`, and:

- the **live `Foo`** logs in if *their* password matches, and
- the **imported `Foo2`** logs in if *their* old password matches.

Ambiguous? Login is **refused, not guessed**. The original `Foo` can never be hijacked.

## ⚙️ Settings

| Setting | Default | What it does |
| --- | --- | --- |
| `landfall_enabled` | `false` | **Master switch.** |
| `landfall_login_with_old_password_enabled` | `true` | Enable old-password login. |
| `landfall_login_with_old_username_enabled` | `true` | Enable old-username login. |
| `landfall_force_password_reset_enabled` | `true` | Email a set-password link to imported members with no usable password when they try to sign in. |

## 🔌 Import-tooling data contract

Landfall keeps its data in **plugin-owned tables** — never user custom fields — so a legacy
hash can't *ever* slip out through a serializer. Your migration tooling fills them in.

**`migrated_passwords`** — one row per user:

| Column | Notes |
| --- | --- |
| `user_id` | unique |
| `algorithm` | one of the supported formats above (omit for a reset-required marker) |
| `password_hash` | the stored legacy hash (omit for a reset-required marker) |
| `salt` | for `vbulletin` / `ipb` (others embed their salt) |
| `metadata` | JSON; e.g. `{ "username": "..." }` for `smf` |
| `reset_required` | `true` for members with no importable password — routed to set one on login |

Because the algorithm lives **per user**, you can blend communities from completely
different forum software into a single Discourse site. Couldn't rescue someone's password?
Write a row with just `reset_required: true` — no algorithm, no hash.

**`migrated_usernames`** — one row per prior username per user: `user_id`, `username`
(`username_lower` is derived and indexed for fast, exact lookups).

## 🔒 Security notes

- Legacy hashes live **only** in `migrated_passwords` and are *never* serialized to a client.
- The live username owner is **always** authenticated first — old-username login can't take
  over an existing account, and ambiguous names are refused.
- Both paths sit behind Discourse's existing login **rate limiter**.
- Legacy hashes are **deleted on first successful use**. Bulk-purging stale credentials after
  a grace period is on the roadmap.

## 🛠️ Development

```bash
bundle install
rspec spec/lib/landfall      # fast, pure-logic suite (no Discourse needed)
bundle exec bin/mutant run   # mutation-testing gate — 100%, no excuses
```

The integration specs (`spec/integration`) run inside a Discourse checkout — details in
[`TESTING.md`](TESTING.md).

## 📄 License

**MIT** — see [`LICENSE`](LICENSE). Use it, fork it, ship it.
