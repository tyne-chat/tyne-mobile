# The signal bar in the mobile app

The mobile half of the signal bar: a strip of emoji at the top of the composer. A tap lights a signal
or turns it off, as the account or as the persona the composer writes as; a long press lists who has
it on and lets managers turn one off or reset it. Mobile only shows, toggles and moderates: the bar,
the community switches and the DM switch are edited on the web. Every file here is the fork's. What
the signal bar is, its data and events, the rules every client follows and where the web and mobile
clients differ are in the server guide, tyne-chat/tyne `fluxer_api/src/api/signal_bar/AGENTS.md`
(also under `fluxer/` when that submodule is checked out); read it first. The web client is
tyne-chat/tyne `fluxer_app/src/features/signal_bar/`.

## Where things are

| Concern | File |
|---|---|
| REST: six raw Dio calls | `data/signal_bar_repository.dart` |
| Models, hand-written parsers, `applySignalUpdate` | `domain/signal_bar_models.dart` |
| The bar, each channel's entries, event routing, `affirmPersona` | `providers/signal_bar_providers.dart` |
| Hand-overs from the composer, the picker and sends | `providers/signal_persona_affirmation.dart` |
| The strip, rights, loading on entry, the details sheet, sizing | `presentation/signal_bar_strip.dart` |
| Event routing by name | the `UnknownGatewayEvent` case of `core/gateway/gateway_event_handler.dart`, then `onSignalBarEvent` in `core/providers/gateway_provider.dart` |
| Strings | `signalBar*` keys in `l10n_fork/fork_*.arb` |

The SDK has a generated `SignalBarApi` and models; the app does not use them, and the repository's
comment saying the SDK lacks the endpoints is out of date.

## Where the strip shows

- `features/chat/presentation/widgets/composer/channel_textarea.dart` mounts `SignalBarStrip`, except
  while a message is being edited: on phones first in the composer header (`_forkSignalBarStrip`;
  `_forkHeaderAlwaysOnMobile` keeps that header on every mobile composer), on wide layouts first in
  the `WideComposerFloatingBox` column.
- `channelId` is the open channel, thread or forum post; `guildId` comes from the channel list (`''`
  when the channel is missing there). `ChannelTextarea` is keyed by channel, so each switch builds a
  new strip.
- Where a barrier replaces the composer (a blocked user, no access, a system DM, an announcement
  channel) there is no strip.

## State

| Provider | Holds |
|---|---|
| `signalBarConfigProvider` (`SignalBarConfigNotifier`) | `SignalBarConfig`: `version` (-1 until loaded), `signals`, and the unused `guildId` and `canManage`. `refresh()` shares the request in flight; `ensureLoaded()` and `ensureVersion(v)` call it; a failure keeps the old state |
| `channelSignalsProvider` (`ChannelSignalsNotifier`) | every channel loaded this session, id to entries; and `_disabledChannels`, an instance field outside `state` |
| `signalBarCollapsedProvider` | the caret, in memory, one value for every channel and account |

- A channel is on when it is in the map and not in `_disabledChannels`. An unknown channel is off,
  so the strip stays hidden until its GET returns.
- The providers are not `autoDispose` and do not watch the account: an account switch or sign-out
  leaves them as they are. Only READY resets them (`invalidate()` and `refresh()` in `onReady`), and
  nothing calls `ref.invalidate` on them.
- `SignalEntry` keeps the user's id, `username`, `global_name` and avatar hash, and the persona's id,
  name and avatar hash, parsed by hand with hard casts. `applySignalUpdate` replaces an account's
  entry in place or appends it, so the server's order holds.

## Flows

- **Loading.** `_loadChannelIfNeeded` runs after the first frame, on a channel change, on any change
  of the bar, and when the channel leaves the map (READY). It sends nothing while the bar has no
  signals, while that channel's GET is in flight, or once the channel is in the map: each channel is
  fetched once per session. `loadChannel` replaces the entries and the flag and calls
  `ensureVersion(bar_version)`; a failure stores nothing.
- **Events.** `handleSignalBarGatewayEvent` routes the three events. `CHANNEL_SIGNAL_UPDATE`:
  `ensureVersion`, then the change for a loaded channel. `CHANNEL_SIGNAL_BAR_UPDATE` off marks the
  channel off and empties it; on marks it on and stores an empty list for a channel never loaded,
  which then counts as loaded. `SIGNAL_BAR_UPDATE`: `ensureVersion`.
- **Writes.** Lighting is not optimistic. `deactivate` and `removeUser` remove the entry first;
  `reset` waits for the event. A failure (`on Exception`) refetches the channel once.
- **Lighting.** A tap on an unlit signal lights it as `composerSignalPersona`: `previewPersona` over
  the open composer's text and attachments, with the channel's selected persona (`latchedIdFor`).
  Before personas load, that is the account.

## Signals and personas

`ChannelSignalsNotifier.affirmPersona` is the one place that re-points: the account's own entries in
a loaded channel whose persona differs change locally at once and get one PUT each. Callers go through
`affirmSignalPersona` or `affirmSignalPersonaData`, which take a `SignalProviderReader` (the `ref.read`
of a widget or of a notifier).

| Action | Caller |
|---|---|
| typing | `ChatViewModel.updateMessageText`: every non-empty change, not while editing, not while the composer may not send, not while a tag is half typed (`isUnfinishedPersonaTag`) |
| a pick in the persona picker | `PersonaPickerSheet._affirmPick`, given `signalChannelId` by `PersonaComposerPill` |
| a send | `resolveOutgoingPersona` (`chat/utils/composer/composer_persona_resolution.dart`), which every send path calls; a thread or post not created yet passes no channel and changes nothing |
| a voice message | `ChatViewModel._sendVoiceMessageInner` |

Opening or loading a channel re-points nothing, and neither does a selection made elsewhere.

## The strip

- **Visible** when the bar has signals and the channel is loaded and on.
- **Rights:** `canToggle` is `canSendMessages`, `true` while unknown; without it taps do nothing.
  `canReset` is `guildId.isEmpty`, or Manage Community in `guildPermissionsProvider`.
- **Collapsed** (the caret): only lit signals stay, laid out and sized as their own set; with none lit,
  only the caret is left.
- **Display:** unlit signals in greyscale; at most three badges, then `+N`. A badge is
  `FluxerAvatar.user` with the account's `userId`, so a persona's avatar hash resolves under that
  account's avatars, and a persona without one shows the account's default avatar. `displayName` is
  the persona's name, else `global_name`, else `username`.
- **Long press** opens `SignalDetailsSheet` for everyone. With `canReset` its rows turn one person off
  (one's own through `deactivate`, others through `removeUser`) and a last row resets the signal.
- **Size:** `signalBarSignalSize` keeps 40 dp while one row holds every signal; past that it picks
  30–48 dp so that no row is less than half full, fewest rows first, then nearest 40.
- `SignalBarView` reads no providers and is tested alone. `SignalBarStrip.build` watches no composer
  state, so typing does not rebuild it.

## Network calls

`RetryInterceptor` replays a GET, PUT or DELETE up to 3 times after a connection error, a timeout or a
503, never a 429; after a 429, `RateLimitInterceptor` answers that method and path locally until
`retry_after`. Counts are before retries. Without a bar, only bar GETs go out.

| Action | Requests |
|---|---|
| READY | 1 bar GET and 1 `GET /channels/:id/signals` for the open channel; others are fetched when next opened |
| Opening a channel | 1 GET the first time this session, bar on or off; none after (A → B → A is 2). A thread or forum post: 1 failing GET every time |
| Typing, a pick, a send, a voice message | none, unless own lit signals in that channel name another persona: 1 PUT each, all at once |
| Tapping a signal | 1 PUT or DELETE, and 1 channel GET if it fails |
| Long press | none; "Turn off" or "Reset": 1 DELETE, and 1 channel GET if it fails |
| `SIGNAL_BAR_UPDATE` (one copy per community) | 1 bar GET when the version is newer; later copies share it or find it current |

A failed bar GET is tried again by the next strip mounted, a failed channel GET at the next mount or
bar change. Neither has a cooldown, and neither repeats on rebuilds.

## Rules and traps

- Re-point only through `affirmPersona`, and only for something done in that channel. Never from
  `build` or a listener: a selection made on another device would move the open channel's signals.
- Keep `SignalBarStrip.build` free of composer state: read the composer at the tap.
- Selectors use `isEnabledIn(snapshot, id)`; reading `state` inside a selector trips a Riverpod
  assertion.
- Follow every change to `_disabledChannels` with a `_setChannel`, or the selector does not re-run.
  Before anything calls `ref.invalidate(channelSignalsProvider)`, clear `_disabledChannels` in
  `build()` (root `AGENTS.md`, "Reset instance fields in kept-alive notifiers").
- `composerSignalPersona` reads the open composer's text, whatever `channelId` it is given.
- A change in the server's shapes lands in `signal_bar_models.dart` by hand.

## Known gaps

Tracked in tyne-chat/tyne#148 unless another issue is named.

- `canReset` treats every DM, group DMs included, and any channel missing from the channel list as
  manageable. The server refuses a group DM member who is not its owner: the entry vanishes, then
  comes back with the refetch.
- A loaded channel is not fetched again before READY, so an event the session misses stays missed.
- Threads and forum posts mount the strip and send a GET the API refuses with 400.
- `affirmPersona` has no batch route and no cooldown: one PUT per own lit signal at once, and a
  re-point the server refuses is sent again at the next text change, because the failure refetch
  puts the old persona back.
- A selected persona with `auto_tag_disabled` is dropped by the matcher (tyne-chat/tyne#130), so
  signals light and re-point as the account.
- A malformed event payload throws out of the hand parsers, and the gateway handler does not catch
  it (`lib/core/gateway/AGENTS.md`).

## Where this code hooks into upstream files

- `core/providers/gateway_provider.dart`: the import, two lines at the top of upstream's `onReady`
  (no `// Fork:` comment), the `onSignalBarEvent:` argument.
- `core/gateway/gateway_event_handler.dart`: the `onSignalBarEvent` parameter and field, and the
  routing branch in the `UnknownGatewayEvent` case, shared with personas.
- `channel_textarea.dart`: the import; `_forkSignalBarStrip` and `_forkHeaderAlwaysOnMobile` at the
  end; `|| _forkHeaderAlwaysOnMobile` and two lines in the mobile header; ten lines in the wide
  column, which could be one `_forkSignalBarStrip` call.
- `chat_view_model.dart`: one call each in `updateMessageText` and `_sendVoiceMessageInner`, inside
  the fork's persona blocks.
- Fork-owned files: `composer_persona_resolution.dart`, `persona_picker_sheet.dart`,
  `persona_composer_pill.dart`.

## Tests

- `test/features/signal_bar/`: `signal_bar_providers_test.dart` (a fake repository that records
  calls: parsing, in-place replacement, version refetch, the enabled flag, local removal, the scope of
  `affirmPersona`, loading never re-pointing); `signal_persona_affirmation_test.dart`;
  `signal_bar_repository_test.dart` (each call's method, path and body); `signal_bar_view_test.dart`
  (`SignalBarView`, `SignalDetailsSheet`, the size table).
- `test/core/gateway/gateway_event_handler_missing_events_fork_test.dart`: the three events reach
  `onSignalBarEvent` unparsed.
- **The folder is in neither the nightly gate nor the root list** (tyne-chat/tyne#132): run it by
  name.
- Not covered: nothing mounts `SignalBarStrip` (loading, rights, the lighting persona); no request
  fails or is counted; what the hand-overs do to signals.
- After a change: `flutter test test/features/signal_bar` and the gateway test above. If a hand-over
  moved, also `test/features/chat/composer_persona_resolution_test.dart`,
  `voice_message_persona_test.dart`, `presentation/sheets/persona_picker_sheet_test.dart` and
  `test/features/profile/persona_per_channel_test.dart`. Then the root list.
