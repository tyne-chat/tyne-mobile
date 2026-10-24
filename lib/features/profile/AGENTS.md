# Profiles, and the app's persona core

Upstream's folder is the people layer: the profile sheet and the "You" tab (`UserProfileView`), status
and custom status, presence, notes, relationships and the moderation actions on a profile. The fork keeps
its **whole client-side persona core** here: the models, the tag matcher, the selection state, the
gateway handling, the device cache of other people's personas, the persona editor and the persona
profile. The composer, chat, settings, the signal bar, threads and emoji all read it, so a change here
reaches most of the app. The server side is tyne-chat/tyne `fluxer_api/src/api/persona/` (it has its own
`AGENTS.md`); the web app's counterpart is tyne-chat/tyne `fluxer_app/src/features/persona/`.

## Where things are

| Concern | File |
|---|---|
| Models: own persona, someone else's profile card, settings, tags, signature emojis | `domain/persona.dart`, `public_persona.dart`, `signature_emoji.dart` |
| Tag matching | `domain/persona_matcher.dart` (a port of the server repository's `PersonaMatcher.ts`) |
| Image addresses: persona avatar and banner, display tag icon | `domain/persona_image_urls.dart` |
| Own personas, the selection, settings, the display tag | `providers/persona_providers.dart` |
| Other people's persona profiles | `providers/public_persona_provider.dart` |
| Persona gateway events | `providers/persona_gateway_events.dart` (`handlePersonaGatewayEvent`) |
| The device's persona cache | `data/known_personas.dart` (Drift table `known_personas`) |
| Create, edit, delete | `presentation/sheets/edit_persona_sheet.dart` |
| The persona profile | `_buildPersonaProfile` in `presentation/widgets/user_profile_view.dart` |

The persona settings page is in `lib/features/settings`; the composer's persona resolution, the picker
and "React as…" sheets and persona mentions are in `lib/features/chat`.

## Which persona: the selection

- **Ask `latchedIdFor(channelId)`** (or `latchedPersonaFor(state, personas, channelId)`): it is the one
  answer to "who does an untagged message here go out as". Never read `activePersonaId` for a channel.
- `activePersonaProvider` holds the mode (`manual`, or `last`: a tagged send moves the selection), the
  scope (`global`, or `channel` with a selection per channel), the selected persona, whether it is
  latched, and local frecency.
- With the per-channel scope, a pick sends `PUT …/personas/channel-states/:id` and re-reads the states on
  failure. `startChannelAs` makes a new thread or forum post start as the persona that opened it.
- The selection is mirrored in SharedPreferences under keys that do not name the account; `reset()` clears
  them on every account switch and sign-out.
- `personaSettingsProvider` loads and patches the server's settings and copies them into
  `activePersonaProvider` and `systemDisplayTagProvider`, which are what the UI reads.

## Matching

`matchPersona`, `previewPersona` and `matchEditMessage` mirror the server repository's `PersonaMatcher.ts`.
A change to one must be made in the other and in both test tables. Known differences: a backslash escapes
even with nothing selected, emoji tags match their shortcode and Unicode forms, and blank text while a
persona is selected. A persona with `auto_tag_disabled` is one whose tags are ignored; the selected
persona should still be used (tyne-chat/tyne#130 is the bug where it is dropped).
`isUnfinishedPersonaTag` keeps typing indicators and signals quiet while a tag is half typed.

## Sending and showing

- **Only the persona's id goes to the server** (`persona_id` on sends, edits and typing). The server
  builds the `subprofile` object messages carry. `Persona.toSubprofilePayload` is a local copy that draws
  pending rows; never send it.
- **Images are hashes, never links.** A persona's avatar and banner and the account's display tag
  icon are hashes of images the server stores under the owning account; the server accepts and sends
  nothing else. Draw them only through `personaAvatarUrl`, `personaBannerUrl` and `personaTagIconUrl`,
  or, for a widget that builds the address from a hash itself (`FluxerAvatar`, which loads an
  http(s), data: or blob: value as it is), through `personaImageHash`. All of them give null for
  anything that is not a hash, so a link is never loaded, whatever a cache or another server holds:
  it would make the app fetch a picture from wherever it points and tell that server who is reading.
- **Other people's personas:** `known_personas` holds every persona the device has seen (from messages'
  `subprofile` and `mention_personas`, persona events it already knew, lookups and profile lookups), with
  its owner (`user_id`) where known: a message's author, the account a `<@userId:personaId>` mention
  names, a lookup's answer. Mention chips, composer labels and thread owners need no request.
  `knownPersonaProvider(personaId)` reads it. A deleted persona keeps its row, as the server keeps
  showing it.
- **Looking a persona up by ID:** `personaLookupProvider((userId, personaId))` asks `POST
  /personas/lookup`, which gives anyone signed in what a message from a persona shows, private ones
  included (tyne-tools#7), through `PersonaLookupBatcher` (`data/persona_lookup.dart`): lookups within
  50 ms share one request, a lookup in flight is shared, and a failed or empty answer is not asked
  again for a while. Thread owners use it.
- **Profiles:** `publicPersonaProvider((userId, personaId))` fetches `GET /users/:id/personas/:pid` once
  per session (failures cached as null); a 403 `PRIVATE_PERSONA` marks it private. Bio and banner come only
  from that fetch. "Private" hides the profile, not the identity: name and avatar are always shown
  (opened from a mention, a private persona's sheet currently falls back to the account's name:
  tyne-chat/tyne#139).

## Gateway events

`handlePersonaGatewayEvent` gets seven event names from the gateway handler (they arrive as
`UnknownGatewayEvent`s; a new name must be added there too). It clears the persona mention cache for the
event's guild, then:

- `GUILD_PERSONAS_DIRTY`: a delete changes nothing shown. An event carrying the persona (public and
  unlisted ones) renames its messages and updates `known_personas` only if the persona is already
  there. Otherwise `PersonaRefresher` (`data/persona_refresh.dart`) waits a second, to collect the copy
  sent per shared community, then fetches again in one request the personas of that account the device
  holds (`knownPersonaIdsOf`: stored with that owner, or on cached messages it sent), and nothing if it
  holds none; it also invalidates the profiles.
- `USER_PERSONA_CHANNEL_STATE_UPDATE`, `USER_PERSONA_SETTINGS_UPDATE`: apply the change.
- The account's own `USER_PERSONA_CREATE|UPDATE|DELETE` and `USER_PERSONAS_UPDATE`: reload the own list
  (one GET from every mobile session of the account), apply the payload's persona, rename messages.

## The editor

`EditPersonaSheet` checks names, tag collisions and signature-emoji collisions locally, then PATCHes or
POSTs **every field**: a caller that passes a partial persona wipes tags, emojis and visibility. Avatar and
banner go through `POST /users/@me/personas/avatar|banner`, checked against the instance's image limit.
There is no control for `auto_tag_disabled`; it is carried over.

## Network calls

- **Start-up:** `reloadSilently()` on providers being read for the first time doubles their first GET, and
  READY loads again: up to about nine persona requests, none shared. Every foreground resume and READY
  repeats the three loads.
- **Own persona events** cost one list GET per mobile session each; the web's "Replace all", which
  deletes one persona per request, multiplies that.
- Nothing here sends per message or per render.

## Where the fork's code sits in upstream files

`_buildPersonaProfile` (about 440 lines) sits mid-class in `user_profile_view.dart`, upstream's most-changed
file here, using the state's private helpers; a fork-owned widget given the close and message callbacks
would leave one line in `build`. `UserProfileBanner` gained a hash branch no caller uses. After a rebase
that touches `UserProfileView`'s `build`, constructor or private constants, check the persona profile.

## Tests

- Fork: `test/features/profile/persona_*_test.dart` (matcher with the unfinished-tag table, providers,
  per-channel scope with a request-counting adapter, gateway events, models),
  `data/known_personas_test.dart`, `providers/public_persona_provider_test.dart`,
  `presentation/sheets/edit_persona_sheet_test.dart`, `user_profile_view_fork_test.dart`,
  `domain/persona_image_urls_test.dart`;
  `test/fork_support/wait_until.dart` instead of sleeps.
- Request counts: `data/persona_lookup_test.dart` and the "without naming one" group of
  `persona_gateway_events_test.dart`.
- Not covered: request counts for profile lookups; a private or unreachable persona profile.
- After a change: `flutter test test/features/profile` (in the nightly gate) and the chat persona tests
  (`composer_persona_resolution_test`, `typing_sender_persona_test`, `voice_message_persona_test`,
  `channel_persona_mention_cache_test`).
