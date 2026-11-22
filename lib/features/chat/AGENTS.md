# The chat feature

Everything about one open conversation: the message engine and list, the composer, the chat screen
with its header, search and sheets. It is upstream's design (about 110,000 lines, and the code
upstream changes most). The fork threads personas through it (sending, editing, reactions, typing,
mentions, the header) and adds inline timestamps and a few composer changes. Most fork code here sits
inside upstream's files, so read "Where the fork's code sits" before editing.

## Map

| Part | Folders | Start with |
|---|---|---|
| Messages: engine, data, list, rows | `providers/core`, `providers/messages`, `data`, `domain`, `presentation/widgets/{messages,message_actions,embeds,media,attachments}`, `utils/{messages,media,embeds,attachments}` | `ChatViewModel` (`providers/core/chat_view_model.dart`), `MessageRepository`, `MessageList`, `Message` |
| Composer | `presentation/widgets/{composer,pickers}`, `utils/composer`, `providers/{pickers,upload,slowmode}`, `presentation/menus` | `ChannelTextarea`, `ChatComposerColumn`, `CloudUploadController` |
| Screen, sheets, services | `presentation/{sheets,pages}`, `presentation/widgets/channel`, `providers/channel`, `services`, `utils/search`, `wallpaper` | `ChannelLayout`, `ChannelChatContent`, `ChannelChatPanel`, `ChannelHeader`, `services/composer_*` |

`services/` holds plain classes the composer owns (`ComposerMentionController`, `ComposerTextSession`,
`ComposerKeyboardSession` and others): created and disposed by their widget, not providers.

## The message engine

- **One `ChatViewModel`** (kept alive) holds the open channel's window of messages, plus up to four
  parked windows. A widget compares `state.channelId` with its own channel before trusting
  `messages`. `ChannelChatContent` calls `switchChannel`, and only while its channel is the active
  route (`activeChannelIdProvider`) and no shell popup is open.
- **Every write to `messages` carries a `MessagesOrigin`**
  (`copyWith(write: (messages: …, origin: MessagesOrigin.x))`). `MessageList` reacts per origin:
  follows the tail for new and own messages, reveals older pages gradually, re-anchors on a window
  swap. A write without an origin gets none of this.
- **`Message` is immutable.** A field that changes how a row looks must be in `isRenderEquivalent`,
  or `MessageTileCache` keeps showing the old row.
- **Realtime:** new messages are batched to the start of the next frame
  (`MessageRealtimeFrameBatcher`); reactions are written to Drift (`ReactionWriteBatcher`) and the view
  model re-reads the row.
- **Paging** (`MessagePaginationCoordinator`): at most `PumpBudget.maxRequestsPerPump` requests per
  pump, then a pause; a failed page parks that edge until the next scroll gesture. Identical page
  requests share one future.
- **The 400-message limit** (`kMaxLoadedMessagesHard`): a full list loads no further page until it
  trims, and upstream trims around the rows that are laid out, when a scroll comes to rest or after
  2 s without one. On the skeleton past the loaded messages no row is laid out, so the fork's
  `presentation/widgets/messages/message_list_skeleton_trim_fork.dart` (a `part`, called from
  `_maybeTrimDetachedWindow`) keeps the 120 messages at that end and restarts paging
  (tyne-chat/tyne#633). Drop it once upstream trims there itself.
- **A jump inside the open channel** (`goToRepliedMessage`: a notification or link for the open
  channel, the jump to the first unread message, a reply preview) loads the page around its target.
  The server sends up to 25 newer messages, the target and up to 24 older ones, and does not make up
  for a short side, so only the older side says whether older messages remain:
  `forkAroundPageHasOlder` (`providers/core/fork_around_page.dart`, tyne-chat/tyne#199).
- **Opening at NEW** (upstream): `MessageList` anchors the first unread message at the middle and
  lowers it in a few settle passes, then never again. The fork's
  `presentation/widgets/messages/message_list_unread_open_fill_fork.dart`, a `part` of
  `message_list.dart` started from `_finishUnreadOpenSettle`, checks after every frame while the list
  stays in that layout. When nothing newer is left to load, it lowers NEW until the rows reach the
  bottom, measured from the slivers' layout extents because rows slide into place after a window
  swap (tyne-chat/tyne#495). Drop it once upstream refits the unread layout itself.

## Fragile: changing state while the list lays out

The list builds rows lazily during layout. Anything that marks a widget dirty while layout runs (a
scroll notification while the keyboard resizes the list, a row registering in
`didChangeDependencies`, a `setState` from a listener) lands mid-frame. Two failures were caught on
phones: a rebuild in the wrong build scope that detached the sliver being laid out (a null-check
crash, frozen list and composer), and a `LayoutBuilder` that lost a rebuild in release builds and
froze the panel on the previous conversation.

- Keep the scroll view's subtree inside `MessageListScrollViewBuildScope`
  (`messages/message_list_viewport.dart`).
- A layout builder whose subtree holds the message list must be a `RebuildSafeLayoutBuilder`
  (`lib/shared/widgets/`); `ChannelChatPanel` wraps the list and the composer in one.
- Never write provider state, call `setState` or notify listeners synchronously from the scroll
  handlers, a row's `didChangeDependencies`, or anything else that can run during layout. Defer to a
  post-frame callback that checks `mounted` (and, in `MessageList`, the anchor epoch).
- Regression tests: `presentation/widgets/messages/message_list_build_scope_test.dart` and
  `test/shared/widgets/rebuild_safe_layout_builder_test.dart`. Their control cases fail on purpose
  without the guard. The second is not in the nightly gate yet (tyne-chat/tyne#132): run it by hand.
- Unit tests cannot show a release-only freeze is gone: have the change tried on a phone (fast
  scrolling while the keyboard opens, opening a DM from a notification, jumping to a reply).
  `[LayoutBuilderRescue]` in the log names a widget written during layout.

## The composer

- **`ChannelTextarea`** is keyed by channel in `ChatComposerColumn`. When writing is impossible it
  renders a barrier instead (system DM, blocked user, no permission, announcement channel).
- **Wire text, not display text.** The field shows inline tokens (mentions, emoji, timestamp chips);
  `ComposerMentionController.toWireText()` is what is measured, stored as the draft and sent.
- **The send order** in `_onSendPressed` matters: commands → slowmode → a lone `\\` → persona →
  `_confirmMentionsIfNeeded` (@everyone, large roles) → reset → `sendMessage`. Until the reset the
  composer still holds the text, so a second tap on Send reads it and sends it again: nothing
  before the reset may wait for a request (tyne-chat/tyne#882). The fork's steps change state on
  the device and leave their saves running.
- **Outside widgets reach the composer only through the pending providers**
  (`pendingEmojiInsertProvider`, `pendingGifSelectionProvider`, `pendingStickerSelectionProvider`,
  `pendingFavoriteMemeSelectionProvider`, `pendingTimestampInsertProvider`), which `ChannelTextarea`
  consumes.
- **Autocomplete** re-checks its generation after every `await`; keep that when adding a source.
- **Stickers and saved media in the `:` list** (tyne-chat/tyne#777): with "Show stickers" and "Show
  saved media in expression autocomplete" on, up to five of each follow the emojis, as on the web.
  The rules are in `utils/composer/fork_expression_autocomplete_media.dart`, the rows in
  `composer_autocomplete_expression_media_fork.dart` (a `part`, called once from `_syncEmoji`). A
  pick sends at once and empties the composer, so they are listed only while it holds nothing but
  the query or a persona tag the send uses up, checked again on the pick, which takes the query out
  and hands over to the `/sticker` and `/saved` handlers. Local data only: no request per keystroke.
- **Uploads:** `CloudUploadController(channelId)` stages attachments; `claimForMessage` hands them to
  the send, which falls back to multipart if a pre-upload failed.
- **Files in an edit** (tyne-chat/tyne#293): an edit happens in the composer, so its files are the
  composer's. `_forkSaveEditWithFiles`, at the end of `ChatViewModel`, adds them to the message,
  under the web app's rules (`InlineEditUploads.ts`): the edit stays open until they
  land, uploading from the composer (`prepareComposerFiles`) rather than a claim, so a failure loses
  nothing. Send does nothing while a save runs. Text typed or files added meanwhile stay for the next
  Send. Removing or changing a file being saved stops the save, and so does closing the edit, but
  not opening another. `editMessageWithFiles` names the attachments the message keeps, read when the
  upload ends: the server drops the rest. The limit on files is checked at Send, because the
  composer's checks count only the composer's files.
- **Keyboard (Android IME).** The space under the composer is shared by the keyboard and the emoji and
  attachment panels. `MobileKeyboardMetrics` and `BottomInputSlot` (upstream) resolve its height;
  `ChatComposerColumn` re-syncs the keyboard metrics on resume (upstream). The fork's part is in
  `android/…/ForkMainActivity.kt` (`MainActivity`'s base class), which replays the window insets
  when the window regains focus because Flutter can lose the last one (`android/AGENTS.md`). Check
  keyboard changes on a device: keyboard ↔ panels, the notification shade, recents.

## Personas in chat

- **Sending:** every send path calls `resolveOutgoingPersona`
  (`utils/composer/composer_persona_resolution.dart`): text, stickers, GIFs, memes, drops, and thread
  and forum-post creation. It matches tags against the persona selected for the channel
  (`latchedIdFor`), applies the side effects (moving the selection in `last` mode, clearing it on
  `\\`, re-pointing the channel's signals) and returns the text without its tag plus a local
  `personaData` map. A selection it moves changes on the device at once; its save
  (`PUT …/personas/channel-states/:id` with personas per channel) is not waited for. Only the persona's id goes on the wire (`persona_id`); the map just draws the
  pending row. Voice messages use the selection only.
- **Before the personas load** (tyne-chat/tyne#30): when the persona list, or with the per-channel
  scope the per-channel selections, has not loaded, a message that could go out as a persona waits
  for it (up to `kPersonaSendWait`, joining the load in flight): the account had personas when the
  list last loaded here (`MyPersonasNotifier.hadPersonas`), and a persona is selected in the channel
  or the text carries one of the account's tags as they were then (`knownTags`). If it still has not
  loaded, `resolveOutgoingPersona` returns null: the caller sends nothing and keeps what was typed,
  and a toast offers "Send anyway", which runs the caller's `onSendAsAccount` once as the account
  (`personaSendAsAccountOnceProvider`). Any other message, and every message on a device where the
  list never loaded, goes out at once as before. A leading `\` with a persona selected sends as the
  account without waiting. Forwards and Shift-drops are held without the action. The pill stays
  while the list is missing (`watchPersonaPillVisible`), so the selection can be changed back.
- **Forwards** (the Forward sheet, tyne-chat/tyne#817): `forwardMessage` runs `resolveSheetForward` once
  per forward, with the sheet's pick or, without one, what the sheet shows (`defaultForwardAs`: the
  persona selected where the forward started, else the account). A tag in the comment decides for the
  forward and its comment and a `\` sends as the account, but like a pick it changes no channel's
  selection, even in "last" mode, and records one use. A forward that could go out as a persona waits
  for the list and is held, as above. A stored send keeps its persona, so a retry after
  a restart goes out as it did before.
- **The selection** comes from `features/profile` (`activePersonaProvider`, `latchedPersonaFor`). Threads
  and forum posts resolve against the parent channel (`personaChannelId`).
- **Editing:** `saveEditedMessage` runs `matchEditMessage`; a persona change is a `PATCH` with
  `persona_id` through raw Dio, because the SDK's `editMessage` is multipart. "Change persona" uses
  `MessageRepository.editMessagePersona`, also on a forward (one's own interactive message, not one
  still sending).
- **Showing:** `Message` carries the persona fields from the server's `subprofile`;
  `MessageItem._buildAuthorHeaderRow` draws the name and the account badge. Persona mention chips read
  your own personas, then the device's `known_personas` table (`knownPersonaProvider`): no request per
  row.
- **Reactions:** `resolveEffectiveReactionPersona` picks the persona whose signature emoji it is, then
  a tag in the composer, then the channel's selection. Removing a reaction sends `persona_id`, or `'0'`
  for the account.
- **Your reactions and React as… (tyne-chat/tyne#86):** both are
  `presentation/sheets/persona_reaction_sheet.dart`, with the rules from the web app's
  `features/persona/` in `utils/reactions/own_reactions.dart` (order taken once when a list opens,
  recents, search). A tap on a chip one of your identities reacted with
  opens "Your reactions" (one hook in `message_reactions_bar.dart`, `openOwnReactionsSheetOnChipTap`),
  which a quiet caret on the chip announces (`persona_reaction_chip_caret.dart`); only with the account
  setting `multi_persona_reactions` on and personas on the account (`multiPersonaReactionsProvider` in
  the profile folder). Rows toggle and the sheet stays open until Done. With the setting off,
  `toggleReaction` removes all of your own reactions on a tap of your chip (`_forkRemoveOwnReactions`,
  one `DELETE` per identity in turn, no retry), and React as… is one choice (`reactAsOnly`) that
  closes. Upstream's scrollable sheet keeps its resting height once anything in it was tapped, so the
  body grows it through the scroll controller's drag target when "React as someone else…" opens the
  full list (`_growToFit`).
- **Pinned emojis** (`features/emoji`, `emojiPinsProvider`, tyne-chat/tyne#140): pinned and unpinned
  from the emoji info sheet, for the account or for the persona the picker writes as. The picker's
  frequently used row starts with the account's pins, then the persona's, ahead of the ranking it froze
  when it opened (`_withForkEmojiPins` in `emoji_picker_content.dart`), so a pin shows at once. The
  quick reaction row starts with the account's pins (`quick_reaction_loader.dart`): it knows no
  persona. Deleting a persona drops its pins (`MyPersonasNotifier.removePersona`).
- **Persona mention autocomplete** asks `GET /channels/:id/persona-mentions` through
  `ChannelPersonaMentionCache` (15-minute cache per channel). Mention syncs are not debounced, so with a
  stale cache one keystroke can send two requests; failures are not cached. A fresh answer without a
  query that came back under its limit is the channel's whole list (`complete`), and a query nothing
  matches is then answered from it. Personas seen in the loaded messages only rank the list: other
  accounts' come only from the route, which applies their mention setting, and the account's own
  from `myPersonasProvider`, unless set to nobody (tyne-chat/tyne#652). Do not add callers, and
  count requests in a test if you change it (root `AGENTS.md`, "Network calls").

## Where the fork's code sits

The largest fork edits inside upstream's lines, which conflict first when upstream changes them:

- `providers/core/chat_view_model.dart`: persona parameters on the send methods, rewritten
  `toggleReaction` and edit paths, persona update handlers.
- `presentation/widgets/messages/message_item.dart`: the persona header and badge.
- `presentation/widgets/composer/composer_autocomplete_field_state.dart`: a persona block in the middle
  of `_renderMentionRows`.
- `presentation/widgets/composer/channel_textarea.dart`: the persona step in `_onSendPressed`, the pill,
  and `_forkHandleGifSelection`/`_forkHandleStickerSelection`, which hold copies of upstream's handler
  bodies: an upstream fix to those handlers has to be copied over by hand.
- `services/composer_mention_controller.dart`: persona mentions and timestamp chips.
- `presentation/sheets/message_reactions_sheet.dart`: persona reactors.

The fork-owned files are easier to change: the persona pill and "sending as" row, the persona picker
and "React as…" sheets, the timestamp picker, `composer_persona_resolution.dart`,
`data/channel_persona_mention_cache.dart`, `data/persona_emoji_usage_store.dart`. When you touch an
upstream file above, move fork code out of upstream's lines where you can.

**Tracking links.** Before sending, `utils/messages/url_sanitization_utils.dart` (upstream's) passes
each link through `fork_tracking_url_sanitizer.dart` first: a port of the web app's
`TrackingUrlSanitizer.ts`, function for function, so a link sent from the phone is cleaned like one
from the web (tyne-chat/tyne#844). Its rules, `utils/messages/generated/fork_tracking_url_rules.dart`,
are generated from the web's `TrackingUrlRules.ts` in the `fluxer` submodule by
`dart run tool/gen_fork_tracking_url_rules.dart` (`--check` compares); the nightly rebase reruns it
after moving the submodule, and `fork_tracking_url_rules_fresh_test.dart` fails while they differ.
When upstream changes the web's sanitizer, carry the change into the port; a new rule field makes
the generator fail until both learn it.

## Tests

- `flutter test test/features/chat` covers this folder and is in the nightly gate. For layout changes
  add `test/shared/widgets/rebuild_safe_layout_builder_test.dart`.
- Paging and jump scenarios: `presentation/widgets/messages/fork_message_list_scenario.dart` runs the
  real list on the real chat against `GapServer` (`test/helpers/fork_message_gap_harness.dart`), whose
  pages arrive when the test lets them and whose `around` page is built as the server builds it.
  Upstream's `PaginatingAdapter` fills an `around` page up to the limit, which the server does not.
- Helpers: `test/helpers/composer_channel_textarea_harness.dart` (`pumpComposerChannelTextareaHarness`),
  `pump_fluxer_app.dart`, `open_test_database.dart`; the list has `message_list_test_harness.dart`.
- Persona tests live in `*_fork_test.dart` and `*persona*_test.dart` files next to upstream's.
- Reaction sheets: `presentation/sheets/persona_reaction_sheet_test.dart`,
  `presentation/widgets/messages/message_reactions_bar_fork_test.dart` and
  `utils/reactions/own_reactions_test.dart`, with fakes in `test/helpers/persona_reaction_fakes.dart`.
- Not covered: `changeMessagePersona`; a failing persona edit or reaction; the autocomplete's persona
  requests per keystroke; persona resolution for stickers, GIFs, memes and drops.

## Known differences and gaps

- Sending a sticker, an auto-sent GIF or meme clears the draft, as upstream's app does. The web app
  keeps it (tyne-chat/tyne#122).
- The wide (tablet) layout has no persona pill; tags and the selection still apply.
- Persona side effects run before the @everyone confirmation, so cancelling it keeps them.
- A selected persona with `auto_tag_disabled` is dropped from text sends (tyne-chat/tyne#130).
