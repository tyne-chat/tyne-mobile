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
  `_confirmMentionsIfNeeded` (@everyone, large roles) → reset → `sendMessage`.
- **Outside widgets reach the composer only through the pending providers**
  (`pendingEmojiInsertProvider`, `pendingGifSelectionProvider`, `pendingStickerSelectionProvider`,
  `pendingFavoriteMemeSelectionProvider`, `pendingTimestampInsertProvider`), which `ChannelTextarea`
  consumes.
- **Autocomplete** re-checks its generation after every `await`; keep that when adding a source.
- **Uploads:** `CloudUploadController(channelId)` stages attachments; `claimForMessage` hands them to
  the send, which falls back to multipart if a pre-upload failed.
- **Keyboard (Android IME).** The space under the composer is shared by the keyboard and the emoji and
  attachment panels. `MobileKeyboardMetrics` and `BottomInputSlot` (upstream) resolve its height;
  `ChatComposerColumn` re-syncs the keyboard metrics on resume (upstream). The fork's part is in
  `android/…/MainActivity.kt`, which replays the window insets when the window regains focus because
  Flutter can lose the last one. Check keyboard changes on a device: keyboard ↔ panels, the
  notification shade, recents.

## Personas in chat

- **Sending:** every send path calls `resolveOutgoingPersona`
  (`utils/composer/composer_persona_resolution.dart`): text, stickers, GIFs, memes, drops, and thread
  and forum-post creation. It matches tags against the persona selected for the channel
  (`latchedIdFor`), applies the side effects (moving the selection in `last` mode, clearing it on
  `\\`, re-pointing the channel's signals) and returns the text without its tag plus a local
  `personaData` map. Only the persona's id goes on the wire (`persona_id`); the map just draws the
  pending row. Voice messages use the selection only.
- **The selection** comes from `features/profile` (`activePersonaProvider`, `latchedPersonaFor`). Threads
  and forum posts resolve against the parent channel (`personaChannelId`).
- **Editing:** `saveEditedMessage` runs `matchEditMessage`; a persona change is a `PATCH` with
  `persona_id` through raw Dio, because the SDK's `editMessage` is multipart. "Change persona" uses
  `MessageRepository.editMessagePersona`.
- **Showing:** `Message` carries the persona fields from the server's `subprofile`;
  `MessageItem._buildAuthorHeaderRow` draws the name and the account badge. Persona mention chips read
  your own personas, then the device's `known_personas` table (`knownPersonaProvider`): no request per
  row.
- **Reactions:** `resolveEffectiveReactionPersona` picks the persona whose signature emoji it is, then
  a tag in the composer, then the channel's selection. Removing a reaction sends `persona_id`, or `'0'`
  for the account.
- **Persona mention autocomplete** asks `GET /channels/:id/persona-mentions` through
  `ChannelPersonaMentionCache` (15-minute cache per channel). Mention syncs are not debounced, so with a
  stale cache one keystroke can send two requests; failures are not cached. Do not add callers, and
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

## Tests

- `flutter test test/features/chat` covers this folder and is in the nightly gate. For layout changes
  add `test/shared/widgets/rebuild_safe_layout_builder_test.dart`.
- Helpers: `test/helpers/composer_channel_textarea_harness.dart` (`pumpComposerChannelTextareaHarness`),
  `pump_fluxer_app.dart`, `open_test_database.dart`; the list has `message_list_test_harness.dart`.
- Persona tests live in `*_fork_test.dart` and `*persona*_test.dart` files next to upstream's.
- Not covered: `changeMessagePersona`; a failing persona edit or reaction; the autocomplete's persona
  requests per keystroke; persona resolution for stickers, GIFs, memes and drops.

## Known differences and gaps

- Sending a sticker, an auto-sent GIF or meme clears the draft, as upstream's app does. The web app
  keeps it (tyne-chat/tyne#122).
- The wide (tablet) layout has no persona pill; tags and the selection still apply.
- Persona side effects run before the @everyone confirmation, so cancelling it keeps them.
- A selected persona with `auto_tag_disabled` is dropped from text sends (tyne-chat/tyne#130).
