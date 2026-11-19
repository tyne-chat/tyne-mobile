# The gateway, app side

What happens to a gateway event after the SDK's `GatewayConnection` has parsed it (the socket,
compression, heartbeat, resume and parsing are in `dart_sdk/lib/gateway_client/`). This is upstream's
design; the fork adds the persona on typing and reactions, writes to the known-persona cache, and routes
the persona and signal-bar events.

## Where things are

| Concern | File |
|---|---|
| The event `switch` (82 cases), READY, writes to Drift, about 57 `on…` callbacks | `gateway_event_handler.dart` (`GatewayEventHandler`) |
| One event at a time, flush on dispose | `gateway_event_dispatcher.dart` |
| Typing, voice states, calls, the recovery reset | `providers/gateway_event_providers.dart` |
| Who a user is typing as (fork) | `providers/typing_personas_provider.dart` |
| Presence in and out | `presence_update_batcher.dart`, `gateway_presence_coordinator.dart`, `gateway_lifecycle_presence.dart` |
| READY's guilds, parsed in an isolate | `gateway_ready_guild_parser.dart` |
| Mention context per guild and channel | `message_mention_context_cache.dart` |
| Wiring the callbacks to providers | `core/providers/gateway_provider.dart` (`gatewayEventListenerProvider`) |

## How events are handled

- **Order:** the dispatcher awaits `handler.handle` for each event in turn, except `TypingStartEvent`,
  which is handled at once. Inside the handler, some cases are awaited (READY, message create, update and
  delete, reactions, acks, threads, member chunks, pins) and so stay in order with later events; others
  are fire-and-forget (channels, guild updates, members, roles, emojis, settings). Choose deliberately
  when adding a case.
- **The handler is plain Dart:** it writes Drift, directly or through write batchers, and notifies through
  callbacks; Riverpod is used only in the providers. It holds the user id of the moment it was built, and
  a new connection builds a new handler.
- **A new event class** in the SDK's sealed `GatewayEvent` needs a case here.
- **Batchers:** before a write that bypasses a batcher, flush that row's batcher (remove-all, add-many
  and acks do).
- **Errors are not caught:** an exception in a case or a callback leaves `handle` as an unhandled async
  error, and the queue goes on.
- **`onMessageCreate` fires before Drift has the row:** the handler queues the message write after the
  callback. Code that reacts to the callback must not read the message back from Drift.

## READY, resume and reconnect

- **READY** is full the first time a handler sees a user (it empties 17 account tables, keeping cached
  messages for the same account) and incremental afterwards (it prunes what the snapshot no longer has).
  Both then write users, guilds, channels, roles, members, threads, emojis, DMs, relationships,
  presences, read states and settings in one transaction, and keep the newest 100 messages per channel.
  After it, `onReady` marks the gateway ready and bumps the full-recovery counter, which empties typing,
  voice states and calls.
- **Backgrounded for more than 45 seconds**, the app suspends: the socket closes with 1000, the next
  connect identifies again, and READY comes in incremental mode (upstream's behaviour, which the fork
  adopted on 2026-10-14).
- **A network drop** resumes within the SDK's window: RESUMED writes nothing and bumps only the session
  recovery counter, so typing and voice state are kept.

## The fork's changes

- **Typing as a persona:** the handler emits `onTypingPersona` with the event's `subprofile` as a separate
  statement after upstream's `onTypingStart`. `TypingPersonas` keeps who each user is typing as;
  `channelTypingSubprofileProvider` shows it only while upstream's `TypingIndicators` has the user typing,
  so expiry stays upstream's. Upstream's `TypingIndicators` and `TypingCallback` are untouched: keep it
  that way (tyne-chat/tyne#136).
- **Reactions:** `personaId` goes from `MessageReactionAddEvent`/`RemoveEvent` into
  `ReactionWriteBatcher.enqueue` and `applyMessageReactionDelta`. `MESSAGE_REACTION_ADD_MANY` (DMs only)
  carries each entry's `user_id` and, since the gateway's fix, `persona_id`; `_handleReactionAddMany`
  reads both, so the app's own reactions, shown when they were made, are not counted again
  (upstream counted every entry as someone else's: tyne-chat/tyne#597, tyne-chat/tyne#120).
- **SDK models back into `fromJson`:** never feed an SDK model's `toJson()` into a `fromJson`. The
  generated `toJson()` leaves enum fields as Dart values, so parsing fails (`v as num`) and the parser
  skips the item without a word. With a reply mention preference set, READY dropped the user's own
  member from every guild this way (tyne-chat/tyne#193, fixed upstream in #1048). Use a JSON round
  trip, `jsonDecode(jsonEncode(model))`, as upstream's READY handler does.
- **Skipped items are logged:** the SDK reports what its parser skips (`ForkGatewayParseSkips`,
  `dart_sdk/lib/gateway_client/fork_parse_skips.dart`); `main.dart` installs
  `forkLogGatewayParseSkips()` (`fork_gateway_parse_skip_log.dart`), which writes
  `[Gateway] Fork: skipped …` to App logs, each kind once and again at the 10th, 100th time.
  READY's guilds are parsed in a background isolate, where that hook is not set, so
  `parseReadyGuilds` calls `forkComputeLoggingSkips` instead of `compute`; any other `compute` that
  parses gateway data needs the same (tyne-chat/tyne#193).
- **Members after a reconnect** (tyne-chat/tyne#614): READY in incremental or cache mode keeps the cached
  `members` rows, and upstream never overwrites one, so a nickname or role change missed while the app was
  away stayed old. `fork_member_confirmation.dart` marks, per connection, which cached members the server
  has written since READY, as the web marks restored members (`GuildMembers.ts`). Every READY starts the
  record over, and so does an account change (`resetPersonaStateForAccountChange`); after a READY that
  kept the cache, every cached member of its guilds is unconfirmed until READY's members, an event, a
  chunk, a profile or REST writes it. Then:
  - an embedded member (message, reaction, typing, voice) overwrites an unconfirmed row
    (`_hydrateMemberIfMissing`);
  - a shown unconfirmed member is asked for once more through op 8 (`GuildMemberHydrationService`,
    `guildUserDisplayProvider`, which also re-checks on the full-recovery bump and when its guild comes
    back), never through the per-user REST fallback, at most once per connection; one the reply leaves out
    left while the app was away, and its row is deleted;
  - op 8 requests go one at a time for the whole app: the gateway runs one per socket and keeps one
    waiting, and a third replaces the waiting one, which then gets no answer;
  - a guild READY lists as unavailable is not asked for until its GUILD_CREATE is stored; a GUILD_CREATE
    or GUILD_SYNC of an available guild (sent whenever a guild is opened) confirms the members it
    carries and gives nobody a second request; GUILD_DELETE forgets the guild;
  - the service forgets its non-members on every READY, and a community profile stores the member it
    brings (`fork_profile_member.dart`), or deletes the row of someone no longer in the guild.
  Confirming is a line where server members are written: READY, `_handleMemberUpsert`, GUILD_CREATE,
  `upsertGuildMembersFromSdk` (chunks, REST, the member list's repository, profiles),
  `MemberListDriftSync`. A new path that writes members from the server needs it too; a local partial
  write must not.
- **Known personas:** message create, update and saved-message events upsert the personas a message names
  into Drift (`upsertKnownPersonasFromSdk`), so mention chips need no request.
- **Persona and signal-bar events** arrive as `UnknownGatewayEvent`s and are routed by name in that case:
  seven persona names to `onUserPersonasUpdate` (handled in
  `features/profile/providers/persona_gateway_events.dart`), three signal-bar names to `onSignalBarEvent`.
  A new persona event needs its name in both places. The SDK drops an unknown event whose payload is an
  array before it reaches the handler.

- **Threads in DMs** (tyne-chat/tyne#699): every event about a DM thread arrives as
  `FORK_DM_THREAD_EVENT`, `{"t": <upstream event>, "d": <payload>}`. The `UnknownGatewayEvent` case hands
  it to `forkHandleDmThreadEvent` (`features/threads/fork_dm_threads/dm_thread_gateway.dart`), which fills
  in the guild key `''` for the thread events whose parser needs a `guild_id`, parses the inner event with
  the SDK's `EventParser` and calls `handle` with it, so upstream's cases store it. READY's
  `fork_dm_threads` (the followed DM threads, their read states, the account's switch) is applied by
  `forkApplyReadyDmThreads`, one line inside READY's transaction before cached messages are trimmed;
  both keep the in-memory index of known DM threads (`dm_threads.dart`) that the UI reads first.
  `_handleMessageCreate` counts every message in a followed, unmuted DM thread
  (`forkDmThreadMessageCounts`), as a DM message counts, without marking it as a mention.

The routing block in the `UnknownGatewayEvent` case sits in upstream's most-changed file; a fork function
called with one line before upstream's `if` would shrink it.

## Network calls

The handler sends no HTTP requests. Indirectly: automatic acks go through `AckBatcher`, and the callbacks
in `gateway_provider.dart` refresh the signal-bar configuration and reload personas on READY. Presence
updates are sent only when the presence changes.

## Tests

- Handler tests are plain Dart: `openTestDatabase()`, then
  `GatewayEventHandler(database:, currentUserId:, on…:)` and `await handler.handle(event)`.
- Fork tests: `gateway_event_handler_fork_test.dart` (persona and account reactions, the typing persona
  callback), `gateway_event_handler_missing_events_fork_test.dart` (signal-bar routing),
  `gateway_event_handler_ready_snapshot_fork_test.dart` (READY keeps the own member with a reply
  mention preference set, upstream's fix of tyne-chat/tyne#193; a member that does not parse is
  reported from READY's isolate),
  `fork_gateway_parse_skip_log_test.dart` (the skip log),
  `gateway_reaction_add_many_fork_test.dart` (ADD_MANY with your own reactions and personas),
  `test/features/threads/fork_dm_threads/dm_thread_gateway_test.dart` (the DM thread envelope, READY's
  `fork_dm_threads`, unread counts of DM thread messages),
  `providers/typing_personas_provider_test.dart`,
  `gateway_event_handler_member_confirmation_fork_test.dart` (members unconfirmed after a reconnect; the
  hydration side in `test/shared/services/guild_member_hydration_service_fork_test.dart`, which counts
  the requests).
- Not covered: the seven persona event names in the handler, known-persona writes from events.
- After a change: `flutter test test/core/gateway test/core/providers test/features/profile
  test/features/signal_bar test/features/chat`. The nightly gate runs all of `test/core`.
