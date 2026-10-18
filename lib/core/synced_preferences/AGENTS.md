# Synced preferences

Client settings that follow an account across devices (accessibility and appearance, picker favourites
and frecency, favourite channels, folders, sounds, swipe and double-tap actions…), sent as one protobuf
message, `SyncedPreferences`, base64-encoded in the `synced_preferences` string of the user settings.
The web app writes the same blob from its own `.proto` copy. This folder holds the app's copy, the Dart
generated from it, the store that merges the server's blob into local state and pushes changes, and one
adapter per top-level field. The design is upstream's; the fork splits the phone's chat font size and
message spacing from the desktop's. The server's side (its copy, the web's merge, how the API decodes
and strips old fields) is in tyne-chat/tyne `packages/schema/AGENTS.md`, "Synced preferences".

## Where things are

| Concern | File |
|---|---|
| Hydrate, per-field reconcile, push, retry, `reset()` | `engine/synced_preferences_store.dart` (`SyncedPreferencesStore`) |
| Byte merge by top-level field; decoding | `engine/synced_preferences_engine.dart` (`mergeIncoming`) |
| Splicing fields into a blob, checking nothing else changed | `engine/synced_preferences_wire_codec.dart` |
| Adapter contract; the base that starts from the server's copy | `engine/synced_field_adapter.dart`, `engine/proto_synced_field_adapter.dart` (`mergeOrCreate`) |
| Top-level numbers; registered adapters (27) | `engine/synced_preference_field.dart`, `engine/synced_field_registry.dart` |
| Accessibility ↔ appearance, advanced, theme | `fields/accessibility_synced_field.dart`, `synced_theme_hydration.dart` |
| Wire format | `proto/fluxer/user/preferences/v1/*.proto` → `generated/` (committed) |
| Hydrate callers | READY, `USER_SETTINGS_UPDATE` (`core/gateway/gateway_event_handler.dart` → `_handleUserSettingsHydrate` in `core/providers/gateway_provider.dart`); `ThemePreference.load` |
| `reset()` callers | `AppStartup._leaveBoundAccount`, `AccountManager.signOut`, `expireSessionIfInvalid` |

The settings live with their owners (notifiers in `lib/features/*` and `lib/core/theme`), some persisted
in Drift (`user_preferences`, the favourites tables: `lib/core/database/AGENTS.md`), some in memory and
refilled at each hydrate. Theme, locale, time format and AFK are plain user settings
(`features/settings/providers/user_settings_sync_service.dart`), not this blob.

## How a setting travels

**Out.**
1. The owner's setter updates and persists its state, then calls `markDirty(SyncedPreferenceField.x)`
   (or `ref.markSyncedDirty`), unless it is applying a remote value (its own `_isApplyingRemote`).
2. The store waits 500 ms after the last change (1.5 s while channel frecency or an expression picker is
   dirty). Nothing is sent before a hydrate from the server (`fromCache: false`), while remote values are
   applied, or while a push is in flight (changes then queue one follow-up).
3. `_flushPush` sends the fields that are dirty and differ from the last server blob by `statesEqual`.
   Each one's bytes are built on the server's copy of its sub-message (`toProtoMessageForPush`), must
   pass `verifyRoundtrip`, and are spliced into the last server blob.
4. The whole blob goes out as `PATCH /users/@me/settings`. On success it becomes the store's wire and
   the fields count as acknowledged for 60 s.
5. Dirty names are saved per user in `user_preferences`; after a restart only adapters with
   `keepsUnpushedEditsAcrossLaunches` (favourites, skin tone, the three pickers, NSFW agreements) get
   them back. An unsent change to anything else gives way to the server's value.

**In.** `hydrateFromUserSettings` runs on READY's `user_settings`, on `USER_SETTINGS_UPDATE` (merged into
the cached `user_settings` row first), and at start-up from the cached row (`fromCache: true`):
1. An empty blob after the first hydrate is ignored; one Dart cannot decode is not merged.
2. `mergeIncoming` takes the server's bytes per top-level field, except that dirty or in-flight fields
   (on the first hydrate, restored dirty fields) keep local bytes, as does a field acknowledged in the
   last 60 s whose incoming bytes equal what was pushed.
3. `_reconcileRegisteredFields`, per adapter: an unprotected field takes `mergeRemote` (by default the
   remote) into its owner through `applyRemote`, and is pushed back if the result differs. A field
   missing from a non-empty blob resets to `clearedRemoteValue` where the adapter has one; local data
   meeting an empty blob is pushed. A field changed before the launch's first hydrate goes through
   `mergeForMigration` when both sides differ. A protected field keeps its value, save what
   `hasInboundUpdatesWhileProtected` lets through (accessibility: saturation, custom CSS).
4. Saturation, CSS, chat font size and zoom go to `ThemePreference`; then `hydrations` fires.

**Conflicts.** The API keeps whichever blob arrives last, with no version check, and sends
`USER_SETTINGS_UPDATE` to the account. Each client builds its save from the last blob it received, so
two devices saving at once can undo each other's change to another field.

## Fields the app does not know

- **Top level:** a push replaces only the dirty fields' chunks, and the codec throws
  `SyncedPreferencesWireEncodeException` (push dropped) if any other chunk changed. Undeclared fields,
  and declared ones without an adapter (spellcheck, keybinds…), go back byte for byte.
  `SaveCameraUploadsSyncedField` reads the undeclared top-level 113 through `unknownFields`.
- **Inside a sub-message:** `ProtoSyncedFieldAdapter`, `AccessibilitySyncedField.toProtoForPush` and
  the expression pickers start from the server's copy with `mergeFromMessage`, which in the `protobuf`
  package carries unknown fields over. So a phone save writes back fields it does not declare (the
  web's fork accessibility fields 2221 and 2222) and declared ones it does not write (the desktop's
  `font_size` and spacings). Read in the code and the package; no test covers it.
- **Replaced wholesale:** `FavoritesSyncedField`, `GuildFoldersSyncedField`,
  `LocalSpamOverridesSyncedField`, `UnreadChannelsSyncedField` build their sub-message from scratch and
  drop whatever another client added inside it (tyne-chat/tyne#154).
- **Wrong wire type:** Dart keeps a declared number arriving with another wire type as an unknown
  field and writes it back. The API refuses such a blob on save, and the web reads it as empty
  (tyne-chat/tyne#125).

## The fork's changes and where they hook in

- `accessibility.proto`: the `// Fork fields.` block at the top of `AccessibilitySettings` holds
  `mobile_font_size`, `mobile_message_group_spacing`, `mobile_compact_message_group_spacing`
  (2224–2226), as in the server's block. `show_alt_text_on_images` is upstream mobile's own setting;
  its number is being settled in tyne-chat/tyne#146.
- `fields/accessibility_synced_field.dart`, inside upstream's lines: three `has…InProto` flags on
  `AccessibilityLocalState`; `fromProto`, `toProto`, `toProtoForPush`, `_merge` and `applyRemote` use
  the `mobile_*` fields instead of `font_size` (12), `message_group_spacing` (10) and
  `compact_message_group_spacing` (60). `_merge` and `AppearancePreferences.applySyncedAccessibility`
  keep the local value when a mobile field is absent. Upstream's `hasFontSizeInProto` (which
  upstream's tests assert after a round trip) is set from `hasMobileFontSize()`: in the fork it means
  the phone's font size.
- `synced_theme_hydration.dart`: the chat font size comes from `mobile_font_size`.
- `engine/synced_preferences_store.dart`: a `wireBlob` getter nothing calls.

The adapter and the store are the files upstream changes most here: keep the fork's edits small.

## Adding a fork field

1. Number it by the root `AGENTS.md` ("Numbers upstream hands out"), never a number either copy used
   or reserved. Add it to the server's copy first, and to the web's store if the web rebuilds that
   sub-message on save; that must reach the web before an app release writes the field.
2. Add the same name, number and type to the fork block here, touching nothing else. A field the phone
   neither reads nor writes need not be declared: it passes through.
3. Regenerate (below) and commit `generated/` with the `.proto`.
4. In the adapter: read in `fromProto`, write in every builder, compare in `statesEqual`, merge in
   `_merge` or `mergeRemote`. If other clients may lack it, keep a `has…InProto` flag and the local
   value when it is absent, in the owner's `applySynced…` too. The owner marks it dirty on change.
5. Tests in a `_fork_test.dart` file: round trip, absent field keeps local, a push keeps the server's
   other fields.

A new top-level field also needs a `SyncedPreferenceField` value (last, under `// Fork values.`; dirty
fields are stored by name), a registration line in `registerDefaultSyncedFieldAdapters`, and a new
count in upstream's `synced_field_registry_test.dart` (ask a maintainer). A varint scalar pushes with
`fieldPushWireType => 0` and `encodePushValueBytes`.

**Regenerating:** from `proto/`, `protoc --dart_out=../generated -I . $(find . -name '*.proto' | sort)`
into an emptied `generated/`, with exactly the `protoc_plugin` upstream used (25.1.0 in October 2026;
25.0.0 already differs). On upstream's `.proto` files it must reproduce upstream's `generated/` byte
for byte.

**Retiring a field:** stop using it and replace its line with `reserved` (number and name) in both
copies. The phone keeps sending the stored bytes back as an unknown field, so if they could break a
decoder the API strips them (`RetiredSyncedPreferenceFields.ts`). Never reuse the number.

## Rules and traps

- **Two copies, by hand.** This one follows upstream's mobile app, which already differs from the
  server's (accessibility 42 and 43, top-level 113). Only the fork block mirrors the server's; nothing
  checks it.
- **Declare a number with the server's type.** Bytes of another wire type break the API (it refuses
  every later save of the account) and the web (it reads the blob as empty), not the phone.
- **`writeProto` starts from the server's copy:** set or clear every modelled field, and `clear()`
  repeated and map fields before adding.
- **`statesEqual` covers every field.** A change to a field it ignores is never pushed. An unstable
  `verifyRoundtrip` skips the whole push, every field, and re-arms the debounce, over and over,
  without sending.
- **Converge.** A merge that never equals the remote marks the field dirty after every hydrate, and
  each echo brings another push.
- **Applying remote values never marks dirty:** keep the owner's guard around `applySynced…`.

## Network calls

| Action | Requests |
|---|---|
| READY, `USER_SETTINGS_UPDATE` (the echo of a save too) | none: the blob is in the event |
| Start-up without a cached settings row | 1 `GET /users/@me/settings` (`ThemePreference.load`) |
| A settings change | 1 `PATCH` of the whole blob 500 ms after the last change; changes during it, one more |
| Browsing channels | channel frecency changes on each switch: 1 `PATCH` per 1.5 s pause |
| A server blob Dart cannot decode | up to 1 favourites repair `PATCH` per hydrate, no cooldown |

A failed push, a 400 included, is retried after 2, 4, 8, 16, 32 and 60 s (after a 429, its
Retry-After clamped to 0.25–60 s), then dropped until the next change; a change during the back-off
does not reset it. Retrying a 400 and the repair's missing cooldown are tyne-chat/tyne#154. `RetryInterceptor` replays a `PATCH` only after a connection failure, and
`RateLimitInterceptor` answers locally inside a 429 window.

## Tests

- `test/core/synced_preferences/`, in the root list through `test/core`. Engine:
  `synced_preferences_wire_codec_test.dart` (top-level foreign fields kept),
  `synced_preferences_engine_test.dart`, `synced_preferences_dirty_push_test.dart`,
  `synced_preferences_push_retry_test.dart`, `synced_field_registry_test.dart` (the adapter set).
- Store tests each define a fake `UsersApi` (most count pushes: `pushCount`) and fire the timers
  through `test/helpers/synced_preferences_test_helpers.dart` (`flushSyncedPreferencesDebounce`): no
  test waits on the clock.
- Fork: `accessibility_synced_field_fork_test.dart`, importing upstream's
  `accessibility_synced_field_test.dart` `hide main` for the helpers named in its appended block.
  Older fork tests still sit in upstream's files and could move: two fixture lines and four assertions
  in "toProtoForPush preserves desktop-only fields from wire base", and three tests at the end of the
  first group of `accessibility_theme_sync_store_test.dart`.
- Not covered: a push keeping an undeclared field inside a sub-message, or a wrong-wire-type value;
  the two copies' fork blocks against each other.
- After a change: `flutter test test/core/synced_preferences`, the owner's tests if a setter or
  `applySynced…` changed, then the root list.
