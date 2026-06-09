# Landfall

A migration-companion plugin for [Discourse](https://www.discourse.org). Landfall
smooths the cutover when you import one or more communities into Discourse — starting
with letting members keep logging in after the move.

It is a sibling to the MIT [`discourse/markbridge`](https://github.com/discourse/markbridge)
markup-conversion gem. See [`IDEAS.md`](IDEAS.md) for the broader roadmap and
[`TESTING.md`](TESTING.md) for the quality standard.

## Features (v1)

### Log in with the old password

Imported users usually arrive with **no Discourse password**, forcing everyone through
a reset on day one. Landfall lets members log in with the password they used on the old
forum: when Discourse's native check fails, it verifies the entered password against a
stored legacy hash. On a match it **re-hashes the password to Discourse's native
algorithm and deletes the legacy hash** — so the legacy hash is used exactly once.

Supported legacy formats: `md5`, `sha1`, `sha256`, `sha512`, `bcrypt`, `vbulletin`,
`ipb`, `smf`, `joomla`, `crypt`, and `phpass` (WordPress / phpBB3).

### Log in with the old username

Discourse's username rules and de-duplication often **rename** members during import.
Landfall lets a renamed member log in with their previous username. It resolves the
typed name to the user's current username before the normal login runs, so rate
limiting, 2FA, and session handling are all reused unchanged.

It also handles the **live-username collision** case: if the imported community had a
`Foo` that was renamed to `Foo2` because the destination already had a different `Foo`,
typing `Foo` logs in the live `Foo` when their password matches, and the imported
`Foo2` when *their* old password matches. If the name is ambiguous, login is refused
rather than guessed — the live owner can never be hijacked.

## Settings

| Setting | Default | Description |
| --- | --- | --- |
| `landfall_enabled` | `false` | Master switch. |
| `landfall_login_with_old_password_enabled` | `true` | Enable old-password login. |
| `landfall_login_with_old_username_enabled` | `true` | Enable old-username login. |

## Import-tooling data contract

Landfall stores its data in **plugin-owned tables** (never user custom fields), so a
legacy hash can never leak through a serializer. Your migration tooling populates them:

`migrated_passwords` (one row per user):

| Column | Notes |
| --- | --- |
| `user_id` | unique |
| `algorithm` | one of the supported formats above |
| `password_hash` | the stored legacy hash |
| `salt` | for `vbulletin` / `ipb` (others embed their salt) |
| `metadata` | JSON; e.g. `{ "username": "..." }` for `smf` |

Because the algorithm is stored **per user**, you can merge communities coming from
different forum software into one Discourse site.

`migrated_usernames` (one row per prior username per user): `user_id`, `username`
(`username_lower` is derived and indexed for fast, exact lookups).

## Security notes

- Legacy hashes live only in `migrated_passwords` and are never serialized to
  any client.
- A live username owner is always authenticated first, so old-username login can never
  take over an existing account; ambiguous old usernames are refused.
- Both paths run behind Discourse's existing login rate limiter.
- Legacy hashes are deleted on first successful use. Purging stale credentials after a
  grace period is on the roadmap.

## Development

```bash
bundle install
rspec spec/lib/landfall      # fast, pure-logic suite (no Discourse)
bundle exec bin/mutant run   # mutation testing gate (100%)
```

The Discourse-integration specs (`spec/integration`) run inside a Discourse checkout.
See [`TESTING.md`](TESTING.md).

## License

MIT — see [`LICENSE`](LICENSE).
