# The local database

The app keeps the signed-in account's data in one SQLite file through Drift: users, servers, channels,
messages, members, read states, settings, plus a few device tables (stored sessions, push registrations,
recent instances). Screens read it through DAO `watch*` streams; the gateway handler, the repositories
and the write batchers write it. This is upstream's design. The fork adds a persona cache table and
persona columns, without schema versions of its own.

## Where things are

| Concern | File |
|---|---|
| Tables, DAOs, migration steps, clear helpers | `fluxer_database.dart` (`FluxerDatabase`) |
| One table or one DAO | `tables/`, `daos/` |
| Opening the file (background isolate, read pool), pragmas | `sqlite_connection.dart`, `sqlite_pragmas.dart` |
| Cancellation-safe streams (every `watch*` ends with it) | `drift_stream_utils.dart` |
| The fork's columns and tables on existing files | `fork_schema.dart` (`ensureForkSchema`) |
| The fork's persona cache table and its API | `tables/known_personas.dart`; `features/profile/data/known_personas.dart` |
| The provider | `core/providers/database_provider.dart` (`fluxerDatabaseProvider`, one per process) |

Generated code: Drift writes `fluxer_database.g.dart` and a `.g.dart` mixin per DAO. They are not
committed: after changing a table or a DAO, and after pulling, run
`dart run build_runner build --delete-conflicting-outputs`.

## Three kinds of table

- **Account cache:** almost everything, the fork's `known_personas` included. `clearAccountData()`
  empties it when the app switches account while running; after a cold start into another account,
  READY's wipe does the clearing.
- **Per user, kept across switches:** `user_preferences`, emptied only by `clearUserData()` at sign-out.
- **Device:** `auth_sessions`, `mobile_push_registrations`, `recent_instances`, never emptied.

READY rewrites most account tables in one transaction unless it is a reconnect of the same user, keeps
cached messages for the same account, and prunes them to known channels and 100 per channel.

## Schema changes

**Upstream's way:** `onCreate` runs `createAll()`, so a new install gets every declared column and runs no
step. `onUpgrade` is one chain of `if (from < N)` steps. Since step 67 every step checks before it acts,
so running one twice is harmless. A new upstream column means a getter in its table class, a guarded step
under the next number, `schemaVersion` bumped, and the migration test updated.

**The fork takes no schema version numbers.** Drift keeps one ordered counter (`user_version`) and every
step is a `from < N` test, so a fork step next to upstream's collides with upstream's next one: on
2026-10-09 the fork's steps 91 and 92 did, installs already at 92 skipped upstream's 91 and 92, and the
first sync failed with "no such table: thread_members". A high fork number would be worse: every later
upstream step would be skipped for good. So:

- Never change `schemaVersion`, and never add an `if (from < N)` step for fork data.
- Declare a fork column in its table class with a `// Fork:` comment (new installs get it from
  `createAll()`), and add it, guarded, in `ensureForkSchema`, which runs from `beforeOpen` on every open of
  an existing file.
- Give it a test in `test/core/database/fork_schema_test.dart` that removes the column, reopens the file
  and expects it back.
- A one-off fork data change needs a marker to run once; the drop of cached messages that mention
  personas rides on the creation of `known_personas`.

**What a rebase can still break:**

- **Table rebuilds.** Drift's `TableMigration` rebuilds a table from its class and copies every declared
  column, so the fork's columns must exist first. Upstream's step 98 rebuilds `messages` and starts with
  `ensureForkSchema(this, m)` for that reason. A new upstream rebuild of `messages` or `channels`, or an
  upstream test that creates one of them by hand, needs the same.
- **A declared column missing from a file breaks every query on its table** ("no such column"). New
  installs and the "matches fresh onCreate" test do not show it; `fork_schema_test.dart` does.
- **The repair for old installs.** Files from builds made before 2026-10-09 (fork version 92) are
  detected by a missing `thread_members` table or theme-studio column, and upstream's steps rerun from 90.
  It relies on upstream's steps staying guarded, and on the name `thread_members`. Its test,
  `fork_schema_test.dart`, rebuilds such a file by dropping what upstream's steps 91 and 92 add, listed
  by hand in `_threadColumns` and `_themeStudioColumns`: when upstream changes those steps, change the
  lists as upstream changes its own migration test (tyne-chat/tyne#157, `read_states.missing_since`).
  Its removal waits for data on which builds are still in use (tyne-chat/tyne#127, which tracks it with
  the server's settings workaround).
- **`beforeOpen`:** if upstream adds one, call `ensureForkSchema` inside it.

## The fork's tables and columns

- `messages`: `persona_id`, `persona_name`, `persona_avatar`, `persona_tag`, `persona_tag_icon`, the
  message's `subprofile` as it arrived (as upstream keeps `author_name`). `MessageDao.updatePersonaAttributes`
  and `updateAuthorDisplayTag` rewrite them when a persona changes.
- `channels.owner_persona_id`: the persona a thread or forum post was started as.
- `known_personas`: every persona the device has been told about (the persona a message was sent as,
  the personas it mentions, persona events and lookups); mention chips and the composer read it with no
  request. A deleted persona keeps its row.

## Tests

- `test/core/database/` (in the nightly gate through `test/core`): upstream's
  `fluxer_database_migration_test.dart` (the version, guarded columns, rebuilds, "matches fresh
  onCreate") and the fork's `fork_schema_test.dart` (legacy files at 92, `known_personas` and its one-off
  drop, opening twice).
- `daos/message_dao_fork_test.dart` covers `updatePersonaAttributes`; `updateAuthorDisplayTag` has no test.
- Helper: `test/helpers/open_test_database.dart` (`openTestDatabase()`, in memory).
- Run `build_runner` first, then `flutter test test/core/database`.
