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
  still loses the persona, on the server first (tyne-chat/tyne#120).
- **SDK models back into `fromJson`:** never feed an SDK model's `toJson()` into a `fromJson`. The
  generated `toJson()` leaves enum fields as Dart values, so parsing fails (`v as num`) and the parser
  skips the item without a word. With a reply mention preference set, READY dropped the user's own
  member from every guild this way (tyne-chat/tyne#193, fixed upstream in #1048). Use a JSON round
  trip, `jsonDecode(jsonEncode(model))`, as upstream's READY handler does.
- **Known personas:** message create, update and saved-message events upsert the personas a message names
  into Drift (`upsertKnownPersonasFromSdk`), so mention chips need no request.
- **Persona and signal-bar events** arrive as `UnknownGatewayEvent`s and are routed by name in that case:
  seven persona names to `onUserPersonasUpdate` (handled in
  `features/profile/providers/persona_gateway_events.dart`), three signal-bar names to `onSignalBarEvent`.
  A new persona event needs its name in both places. The SDK drops an unknown event whose payload is an
  array before it reaches the handler.

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
  mention preference set, upstream's fix of tyne-chat/tyne#193), `providers/typing_personas_provider_test.dart`.
- Not covered: the seven persona event names in the handler, known-persona writes from events,
  ADD_MANY with a persona.
- After a change: `flutter test test/core/gateway test/core/providers test/features/profile
  test/features/signal_bar test/features/chat`. The nightly gate runs all of `test/core`.
