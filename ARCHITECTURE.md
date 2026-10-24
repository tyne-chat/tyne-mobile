# Tyne mobile architecture

How the Flutter app is put together: its layers, how it starts, where state lives, how the main flows
run, and where the fork's features sit. Read it before changing something that crosses folders. Rules
for making changes are in `AGENTS.md`; folders with traps of their own have an `AGENTS.md` too (listed at
the end). When a change makes this file wrong, fix it in the same commit.

Paths are from the repository root. Upstream (Fluxer's `flutter_client`) renames and moves files often:
trust a class or folder name more than a file path, and check before relying on either. Checked against
the code on 2026-10-17. The server side is described in tyne-chat/tyne's `ARCHITECTURE.md`.

## The app

The Flutter client of Tyne (package `fluxer_app`) for Android and iOS; upstream's desktop code paths
exist but are not shipped. The shipped build is the `canaryUnifiedpush` release flavour, given Tyne's
identity (`chat.tyne.app`, the `tyne://` scheme, the name from `tool/dart_defines/canary.json`). Android
APKs are published as GitHub releases of this repository, which the app's own updater installs; iOS
builds go to TestFlight from a GitHub workflow.

Layers, bottom up: the generated **SDK** (`dart_sdk/`, package `fluxer_dart`), **core** (`lib/core/`:
session, transport, storage, routing), **features** (`lib/features/<area>/`), **shared** (`lib/shared/`:
helpers several features use), and local **packages** (`packages/`: markdown, Android notifications).
Dependencies mostly point down, with known exceptions: `core/providers/gateway_provider.dart` imports
42 feature files (3 of them the fork's) to route events, and `shared` imports feature code in about half
its files.

## Layers

**SDK (`dart_sdk/`).** Generated from the server's OpenAPI spec: one API class per tag
(`lib/<tag>/<tag>_api.dart`), the models (`lib/models/`) and `FluxerClient`. Hand-written only in
`lib/gateway_client/` (exported by `lib/gateway.dart`): `GatewayConnection` (WebSocket with zstd,
heartbeat, resume) and `EventParser`, which turns frames into typed `GatewayEvent`s and anything else
into `UnknownGatewayEvent`. A missing or wrong type is fixed in the server's schema and regenerated
(`dart_sdk/AGENTS.md`).

**core (`lib/core/`):**

| Folder | What it holds |
|---|---|
| `api` | two Dio clients with their SDK clients: `fluxerDioProvider` for the signed-in session and `authFluxerDioProvider` for sign-in; interceptors for auth, retries, rate limits, captcha and sudo; the fork's `X-Tyne-Call-Site` header |
| `instance` | which instance the app talks to: `InstanceConstants`, `InstanceEndpoints`, discovery from `/.well-known/fluxer`, the runtime config. The instance's limits are read in `core/limits` |
| `providers` | app start-up (`appStartupProvider`), the session's bindings, the gateway connection and event listener (`gateway_provider.dart`), app lifecycle |
| `gateway` | `GatewayEventHandler`: one `switch` over 82 event cases that writes Drift and calls about 57 callbacks; `GatewayEventDispatcher`, a serial queue that typing events skip; ephemeral state (typing, voice states, calls) |
| `database` | Drift `FluxerDatabase`: one file for all accounts, tables and DAOs, upstream's numbered migrations, and the fork's `fork_schema.dart` (below) |
| `router` | go_router (`fluxerRouterProvider`): a `redirect` that re-runs on eight providers (auth, start-up, gateway ready, splash, account switch…), a shell route around `AppLayout` with the home, favourites and channel routes; `CurrentUserId` and `AuthState` live here |
| `push` | push: `ApplePushService` on iOS always; on Android `PUSH_PROVIDER` chooses, and the shipped build uses UnifiedPush |
| `synced_preferences` | settings synced through the account: protobuf fields in a base64 blob in the user settings |
| `permissions` | channel permissions from READY's member and roles, cached per channel |
| `observability` | Measure telemetry and error hooks (the logger itself is `lib/core/talker.dart`) |
| `updater` | the fork's in-app updater for the Android APK (GitHub releases) |

**features (`lib/features/<area>/`).** One folder per area, usually split into `presentation/`,
`providers/`, `data/`, `domain/`, `services/` and `utils/`. The largest is `chat` (the message engine,
list, composer and chat screen; it has its own `AGENTS.md`), then `settings`, `ui` (the widget kit, plus
the media viewer and call UI pieces), `voice`, `guilds` and `channels`. `shell` is the frame around every
screen: layouts, the drawer, Back handling, the splash and reconnecting screens. `profile` holds the
fork's persona domain.

**shared (`lib/shared/`).** Name and avatar resolution (`GuildUserDisplay`), member fetching
(`GuildMemberHydrationService`), the markdown adapter, links, gestures, and
`RebuildSafeLayoutBuilder`, one of the message list's layout guards.

**packages (`packages/`).** `fluxer_markdown` renders the markdown AST as widgets;
`fluxer_markdown_native` builds the server's Rust parser from the `fluxer/` submodule
(`packages/markdown_parser/rust` in tyne-chat/tyne) through a native-assets build hook and binds it;
`fluxer_android_notifications` backs notifications and the sound check; a `unifiedpush_linux` stub.

## Start-up

1. `main.dart` builds the `ProviderContainer`, restores the saved instance and starts
   `appStartupProvider` without waiting, then `runApp(FluxerApp)`.
2. The router holds `/loading` (`SplashScreen`) until start-up, READY and the unread counts allow it to
   leave (`splashExitAllowedProvider`).
3. `AppStartup` reads the active session from Drift. Without one it goes to `/login`; signing in stores a
   session (`AuthRepository`) and reruns start-up.
4. With a session it sets the token and `currentUserIdProvider`, binds the gateway (connects when the app
   is in the foreground) and its event listener, and fetches the current user. A 401 from the stored
   instance moves on to the next stored account.
5. READY rewrites the account's data in Drift in one transaction (messages are kept for the same
   account), marks the gateway ready, bumps the full-recovery counter (which empties typing, voice and
   call state), and the fork reloads personas, empties every channel's signals and refetches the bar
   (the open channel's strip then refetches its channel). Deep links and notification taps waiting
   since launch are handled at the end of a successful restore.

On Android, `main` also runs without a screen. A push that finds Tyne not running starts an engine of
its own (`FluxerUnifiedPushService`) whose `main` gets `--unifiedpush-bg` and returns after setting up
push handling. The full app can start with no activity too, in audio_service's engine (Android starting
its media service), and `MainActivity` later attaches to that engine. Until then, the channels
`MainActivity.configureFlutterEngine` registers do not exist (`android/AGENTS.md`, "Bridges to Dart").
Up to 2026-10-23, every such push started the full app as well, because audio_service's plugin starts
its media service from any engine (tyne-chat/tyne#210).

## State

- **Riverpod, generated providers mostly.** Session-wide state lives in kept-alive notifiers. What
  belongs to one account resets when `currentUserIdProvider` changes (about 90 files watch it), plus the
  explicit lists in the sign-out and account-switch paths. A kept-alive notifier keeps its instance
  fields across `invalidate`: reset them in `build()` (`AGENTS.md`, "Flutter and Riverpod rules").
- **Drift is the durable cache of an account:** guilds, channels, DMs, members, messages, read states.
  Most lists read DAO `watch*` streams; unread state runs on `ChannelUnreadSources`; the live member list
  is gateway rows held in memory, with Drift as a side cache.
- **Memory:** `chatViewModelProvider` holds the open channel's window of messages plus a few parked
  windows; typing, voice states and permissions are providers; the fork's persona mention list is a
  process-wide cache.
- **Gateway to state:** the handler writes Drift (through write batchers) and calls callbacks that update
  notifiers; new messages reach the chat through `MessageRealtimeBus`.

## Main flows

**A message arrives.**
1. `GatewayConnection` → `EventParser` → `MessageCreateEvent` → `GatewayEventDispatcher` →
   `GatewayEventHandler`: channel, mentions, `Message.fromSdk`, users and (fork) the personas it names
   are upserted, the read state and notification level decided.
2. The handler calls `onMessageCreate`, then queues the Drift write itself (`MessageWriteBatcher`).
   `gateway_provider.dart` passes the message to `MessageRealtimeBus`.
3. `ChatViewModel` applies new messages at the start of the next frame
   (`MessageRealtimeFrameBatcher`): other channels are ignored, a local send is replaced by nonce, the
   window is trimmed.
4. `MessageList` follows the tail if it was there; `MessageItem` draws the row through
   `MessageMarkdown` and the native parser.

**Sending.**
1. `ChannelTextarea`: slash commands, slowmode, then (fork) `resolveOutgoingPersona` (tags, the persona
   selected for the channel, signals), the @everyone confirmation, then `ChatViewModel.sendMessage`.
2. An optimistic message is added (its id is the nonce) and the send is recorded in Drift
   (`local_message_sends`).
3. `MessageRepository.sendMessage` posts `/channels/{id}/messages` (with `persona_id` when sent as a
   persona) and stores the reply; the server message replaces the optimistic one, and the gateway echo
   is matched by nonce.
4. A failed send is adopted if the server did create it, or marked failed for retry.

**Opening a channel.**
1. The route (guild: `ChannelLayout`; DM: `DMLayout`) → `ChannelChatContent` → `ChatViewModel.switchChannel`,
   only for the active route.
2. The old window is parked. A parked window with nothing new is shown at once and refreshed in the
   background; otherwise Drift's cached messages, then a page from the server.
3. Scrolling pages older or newer messages through `MessagePaginationCoordinator`: at most a few
   requests per pump, and a failed page waits for the next gesture.

## Where the fork plugs in

- **Personas.**
  - Domain and state in `features/profile`: `Persona`, `persona_matcher.dart`, `myPersonasProvider`,
    `activePersonaProvider` (mode manual or last, scope global or per channel, `latchedPersonaFor`),
    `persona_gateway_events.dart`, the `known_personas` table.
  - Chat: the composer's pill and "sending as" row, `resolveOutgoingPersona`, the persona picker and
    "React as…" sheets, persona fields on `Message`, the header badge, persona mentions.
  - Threads and forum posts start as the persona that created them; typing as a persona
    (`core/gateway/providers/typing_personas_provider.dart`); settings: the Personas page (mode,
    scope, display tag, the persona list; `lib/features/settings/AGENTS.md`). PluralKit import and
    export are web-only.
  - Only the persona's id goes to the server; the server builds the `subprofile` object messages
    carry.
- **Signal bar:** `features/signal_bar` (the strip in the composer, its notifiers and the gateway
  events; guide in its `AGENTS.md`).
- **Instance defaults:** Tyne's instance as the default, upstream's hosts treated as ordinary instances,
  the server-list buttons.
- **Updater** (`core/updater`), **inline timestamps** (picker sheet, composer chips, message pills),
  **quick switcher** additions (persistent recents, notes, threads, the floating button), and the
  fork's translation catalogues (`l10n_fork/`, used as `l10n.fork.<key>`).
- **Starts without a screen** (tyne-chat/tyne#210): the push engine leaves audio_service out
  (`android/app/src/main/kotlin/com/fluxer/ForkPushEngine.kt`). The crash-report flag is set only on
  screen (`app_foreground_session_watchdog.dart`). Measure is started again at the first resume when
  the start had no screen (`core/observability/fork_measure_start_on_resume.dart`).
- **Build identity:** `tool/dart_defines/canary.json` (`FORK_*` defines), Android's `canary` flavour
  (`android/app/build.gradle.kts`) and source set (`android/AGENTS.md`), and
  `tool/fork_ios_identity.py`, which gives the iOS project Tyne's identifiers at build time.

## Rules that cut across folders

Most are in `AGENTS.md`; the ones that most often surprise:

- **Numbers upstream hands out:** protobuf fields from 2200, no Drift schema versions of the fork's own
  (`lib/core/database/fork_schema.dart` adds the fork's columns and tables on open), fork enum values
  last, the markdown persona mention kind 255.
- **Network calls:** the server signs a session out over 50 requests per second. Code that runs per
  channel, message or member must share requests and not retry a failure on the next build. Computing
  permissions never asks the server for the user's own member: READY brings it.
- **Message list layout:** never change state while the list lays out (`lib/features/chat/AGENTS.md`).
- **Start-up may have no screen:** on Android, a call at start-up to a channel that `MainActivity`
  registers can fail with `MissingPluginException` and is not repeated by itself. Code that runs at
  start-up and needs one must try again at the first resume. Today only Measure does
  (`fork_measure_start_on_resume.dart`). Upstream's animator-scale provider
  (`core/platform/android_animator_duration_scale.dart`) stays in error for such a process; that is
  left as is, because nothing we have seen still starts one (tyne-chat/tyne#210).
- **Tests** go in fork-owned files; upstream's private helpers are named in a block appended to its test
  file, never copied.

## Glossary

- **guild = community = server:** code and API, UI text, Drift (`Servers`).
- **thread, forum post:** a thread is a channel of a thread type; a forum post is a thread whose parent is
  a forum or media channel, and its first message has the post's id. **Personal notes** is a DM type.
- **persona, subprofile, profile:** an account's alternate identity; the field naming a message's persona
  (built by the server); upstream's user profile. **Known persona:** a persona the device has seen,
  cached in Drift. **Display tag:** the account's tag shown after a persona's name. **Latched / selected:**
  the persona untagged messages go out as.
- **signal:** an emoji a member lights in a channel, from the instance's signal bar.
- **saved media:** favourite memes (`FavoriteMeme`).
- **fluxer_dart, fluxer_app, `fluxer/`:** the SDK, the app, the server repository submodule.
- **Message, MessageResponseSchema, db.Message:** the app's model, the SDK's, the Drift row.
- **READY, RESUMED:** a full rebuild of the account's state, or a light resume.

## Folder guides

These folders have an `AGENTS.md` with their design and traps; read it before changing code under the
folder. A new folder guide is added to this list in the same commit.

- `android/AGENTS.md`: the Android host: build variants and Tyne's identity, the Kotlin bridges, the
  keyboard inset fix, and what breaks installs and releases.
- `lib/core/database/AGENTS.md`: the local Drift database and how the fork changes its schema.
- `lib/core/gateway/AGENTS.md`: how gateway events reach Drift and the providers.
- `lib/core/synced_preferences/AGENTS.md`: settings synced through the account: the protobuf copy,
  how the store merges and pushes, and the fork's mobile layout fields.
- `lib/features/chat/AGENTS.md`: the message engine and list, the composer, the chat screen.
- `lib/features/profile/AGENTS.md`: profiles, and the app's persona core.
- `lib/features/settings/AGENTS.md`: the settings screens, where each setting is stored, and the
  Personas page.
- `lib/features/signal_bar/AGENTS.md`: the signal bar strip, its state and the persona hand-overs.
