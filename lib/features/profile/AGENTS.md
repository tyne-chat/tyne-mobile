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
| Waiting for the first load before a send (tyne-chat/tyne#30) | `providers/persona_first_load.dart` |
| Other people's persona profiles | `providers/public_persona_provider.dart` |
| Persona gateway events | `providers/persona_gateway_events.dart` (`handlePersonaGatewayEvent`) |
| The device's persona cache | `data/known_personas.dart` (Drift table `known_personas`) |
| Create, edit, duplicate, delete | `presentation/sheets/edit_persona_sheet.dart` (the copy's bar: `persona_copy_bar.dart`) |
| The persona profile | `_buildPersonaProfile` in `presentation/widgets/user_profile_view.dart` |
| Changing the visibility of, or deleting, many own personas at once (tyne-chat/tyne#542) | `providers/persona_bulk_actions.dart` (the settings page's select mode uses it) |
| Own deleted personas and Restore (tyne-chat/tyne#610) | `providers/deleted_personas.dart` (the settings page's Deleted personas section uses it) |
| An account's public personas: the "Personas (N)" pill, row and gallery (tyne-chat/tyne#189) | `providers/public_persona_list_provider.dart`, `domain/persona_gallery.dart`, `presentation/widgets/persona_gallery_entry.dart`, `presentation/sheets/persona_gallery_sheet.dart`, `presentation/sheets/persona_profile_pager.dart`, `providers/persona_gallery_view_provider.dart` |

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
- `multi_persona_reactions` ("React as several personas at once", tyne-chat/tyne#86) is mirrored by
  `multiPersonaReactionsProvider` (`providers/multi_persona_reactions_provider.dart`), stored under
  `persona_multi_reactions` and on until the stored value or the server says otherwise. A settings load that a change
  of the switch overtook keeps the change (`_withReactionChoice`).

## Matching

`matchPersona`, `previewPersona` and `matchEditMessage` mirror the server repository's `PersonaMatcher.ts`.
A change to one must be made in the other and in both test tables. Known differences: a backslash escapes
even with nothing selected, emoji tags match their shortcode and Unicode forms, and blank text while a
persona is selected. A persona with `auto_tag_disabled` is one whose tags are ignored; in every other
way it acts like any other persona, also when selected.
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
- **A persona's colour** has one rule, `resolvePersonaColor` in `domain/persona_color.dart` (the web's
  `personaColor` repeats it): the accent colour, else the colour of the persona's own avatar, else
  none. Mentions, typing names and the profile banner all use it; only the settings list shows the
  accent setting itself. A message's `authorAvatarColor` is the account's, never the persona's
  (tyne-chat/tyne#254).
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
- **"Personas (N)"** (tyne-chat/tyne#189): `GET /users/:id/personas` answers an account's public
  personas, the most used first, with its display tag (`publicPersonaListProvider`; a 403 means the
  viewer may not see the profile). The account's profile header shows that display tag after the
  name; wherever a profile shows the display tag (the header, a persona's profile) the "Personas (N)"
  pill follows, and the same count is the first row of the mutuals section (alone in a section on
  your own profile). For others both show once they have a public persona; on your own profile
  always, from `myPersonasProvider` and `systemDisplayTagProvider`, with no request
  (`personaGallerySummaryProvider`). The gallery (cards, list or avatars, remembered per device)
  searches and sorts on the device. It never shows use counts or times: "Most used" is the server's
  order for someone else's personas, "Recently used" and the proxy tags are the owner's only. A
  persona opens in `PersonaProfilePager`, a `PageView` of persona profiles sharing the sheet's scroll
  controller, in the gallery's order. In your own gallery with no public persona, "Choose personas to
  feature" opens the Personas settings on the Unlisted chip in select mode
  (`personaSettingsLaunchProvider`, tyne-chat/tyne#542).
- **Many at once** (tyne-chat/tyne#542): `PersonaBulkActions` sends only the personas that change, in
  one request per 250 (the server's limit, each all or nothing), applies the answer to the list in
  one change (`replacePersonas`), and keeps each persona's previous visibility for Undo. A bulk
  delete drops the personas (`removePersonas`, their pinned emojis in one synced change through
  `forgetPersonas`) and clears the selection and per-channel selections naming them here at once,
  without a request: the server clears them itself and its events follow.

## Gateway events

`handlePersonaGatewayEvent` gets seven event names from the gateway handler (they arrive as
`UnknownGatewayEvent`s; a new name must be added there too). It clears the persona mention cache for the
event's guild, then:

- `GUILD_PERSONAS_DIRTY`: a delete changes nothing shown. An event carrying the persona (public and
  unlisted ones) renames its messages and updates `known_personas` only if the persona is already
  there. Otherwise `PersonaRefresher` (`data/persona_refresh.dart`) waits a second, to collect the copy
  sent per shared community, then fetches again in one request the personas of that account the device
  holds (`knownPersonaIdsOf`: stored with that owner, or on cached messages it sent), and nothing if it
  holds none; it also invalidates the profiles. Every one, deletes included, also asks
  `PublicPersonaListRefresher` to drop that account's public list once the burst of copies is over.
- `USER_PERSONA_CHANNEL_STATE_UPDATE`, `USER_PERSONA_SETTINGS_UPDATE`: apply the change.
- The account's own `USER_PERSONA_CREATE|UPDATE|DELETE` and `USER_PERSONAS_UPDATE`: reload the own list
  (one GET from every mobile session of the account), apply the payload's persona, rename messages.

## The editor

`EditPersonaSheet` checks names, tag collisions and signature-emoji collisions locally, then PATCHes or
POSTs **every field**: a caller that passes a partial persona wipes tags, emojis and visibility. Avatar and
banner go through `POST /users/@me/personas/avatar|banner`, checked against the instance's image limit.
The form's "Don't match this persona's tags" switch sets `auto_tag_disabled`.

**Duplicate** (tyne-chat/tyne#599), above Delete, is off while the form has unsaved changes. It closes the
editor and opens `EditPersonaSheet.show(copyOf:)`: a new persona filled in from the saved one, with the
same picture hashes (nothing uploaded; the server deletes images only with the account), colours,
pronouns, bio, visibility and tag matching, under `duplicatePersonaName` (`domain/persona_duplicate_name.dart`,
the web's rule: "Lyra (2)", a copy of a copy counting on), autofocused and selected. Tags and signature
emojis start empty, since each belongs to one persona. The copy is unsaved from the start: `PersonaCopyBar`
("Copy of …", Cancel, Create) stays up below the form (not over it, where it would cover the field being
typed in) in place of upstream's save bar, and neither a drag, Back nor a close button dismisses it. The
name counts the API's limit in UTF-16 code units and is cut only between whole characters. Create sends the same POST as a new persona.

## Network calls

- **Start-up:** `reloadSilently()` on providers being read for the first time doubles their first GET, and
  READY loads again: up to about nine persona requests, none shared. Every foreground resume and READY
  repeats the three loads.
- **Own persona events** cost one list GET per mobile session each; the web's "Replace all", which
  deletes one persona per request, multiplies that.
- **A send before the list has loaded** (tyne-chat/tyne#30), from an account that had personas when
  the list last loaded here, waits for the load in flight, or starts one, through `FirstLoadGate`
  (`providers/persona_first_load.dart`); after a failure it asks again at most every 10 seconds,
  however many sends wait. The per-channel selections are waited for the same way. Nothing else here
  sends per message or per render.
- **"Personas (N)"**: one `GET /users/:id/personas` per profile opened, shared by the pill, the row
  and the gallery, kept 60 seconds after the last of them goes. A failure is not asked again by
  itself: the row offers Retry, and a failed answer is dropped with its last listener, so the next
  profile opened asks again. A `GUILD_PERSONAS_DIRTY` for the account drops it one
  `personaRefreshDelayProvider` after the last copy, and only a list on screen is fetched again.
  Opening a persona from the gallery fetches its profile once per session, one per persona swiped to.
- **Many at once**: one `PATCH /users/@me/personas/visibility` or `POST /users/@me/personas/bulk-delete`
  per 250 personas, nothing when none would change, never retried; Undo is one more `PATCH`. The
  server's `USER_PERSONAS_UPDATE` then reloads the own list once per mobile session, as one change
  does.

## Where the fork's code sits in upstream files

`_buildPersonaProfile` (about 440 lines) sits mid-class in `user_profile_view.dart`, upstream's most-changed
file here, using the state's private helpers; a fork-owned widget given the close and message callbacks
would leave one line in `build`. `UserProfileBanner` gained a hash branch no caller uses. After a rebase
that touches `UserProfileView`'s `build`, constructor or private constants, check the persona profile.

"Personas (N)" hooks into upstream's files at four places, each handing over to
`persona_gallery_entry.dart` (five with the popout card's): a `forkNameTrailing` widget at the end of `UserProfileHeader`'s name row,
`forkLeadingRows` first in `UserProfileMutualsSection`, and in `_buildLoadedView` a `forkPersonas` local
(null for webhooks, bots and system accounts) passed to those two and to `ownPersonaGallerySection`,
one line above the mutuals. Upstream's `user_profile_view_test.dart` overrides
`publicPersonaListProvider` for the other account under a `// Fork:` comment: a request left running
would fail its tests. The popout card (wide layouts with a pointer, `_buildPopoutCard`) shows the
display tag and pill through one more element in its name `Wrap`.

## Tests

- Fork: `test/features/profile/persona_*_test.dart` (matcher with the unfinished-tag table, providers,
  per-channel scope with a request-counting adapter, gateway events, models),
  `data/known_personas_test.dart`, `providers/public_persona_provider_test.dart`,
  `presentation/sheets/edit_persona_sheet_test.dart`, `user_profile_view_fork_test.dart`,
  `domain/persona_image_urls_test.dart`, `domain/persona_gallery_test.dart`,
  `providers/public_persona_list_provider_test.dart`, `presentation/widgets/persona_gallery_entry_test.dart`;
  `test/fork_support/wait_until.dart` instead of sleeps.
- Request counts: `providers/persona_bulk_actions_test.dart`, `providers/deleted_personas_test.dart`, `data/persona_lookup_test.dart`, the "without naming one" group of
  `persona_gateway_events_test.dart`, and `providers/public_persona_list_provider_test.dart` (shared,
  kept, not repeated after a failure, a burst of change events).
- Not covered: the persona pager (swiping, and dragging a page down to close the sheet).
- Not covered: request counts for profile lookups; a private or unreachable persona profile.
- After a change: `flutter test test/features/profile` (in the nightly gate) and the chat persona tests
  (`composer_persona_resolution_test`, `typing_sender_persona_test`, `voice_message_persona_test`,
  `channel_persona_mention_cache_test`).
