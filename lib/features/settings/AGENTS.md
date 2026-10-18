# Settings

User settings (account, profile, appearance, accessibility, chat, notifications, advanced, billing,
developer pages) and community settings, plus the preference providers the rest of the app reads. The
design is upstream's (about 420 files, mostly page widgets). The fork adds the Personas page and a
device switch for the composer's quick-switcher button, and edits upstream's files to register that
page, add "Check for updates" and a push clean-up on sign-out, and change the profile page. The persona
state the page drives is in `lib/features/profile` (its `AGENTS.md`); how a synced setting is stored
and pushed is in `lib/core/synced_preferences/AGENTS.md`.

## Where things are

| Concern | File |
|---|---|
| The sheet in both layouts, the section `switch`, sign-out | `presentation/user_settings_modal.dart` |
| The sections | `domain/user_settings_section.dart` (`UserSettingsSection`) |
| Navigation lists, icons | `presentation/user_settings_nav.dart` |
| Labels, deep-link tabs | `utils/user_settings_nav_l10n.dart`, `utils/user_settings_deep_link_scope.dart`, `utils/user_settings_field_registry.dart`, `core/deep_links/user_settings_deep_link.dart` |
| Search, scroll to a field | `utils/user_settings_search_index.dart`, `utils/user_settings_section_scroll.dart` |
| Profile editor, server-side user settings | `providers/user_settings_view_model.dart`, `providers/user_settings_sync_service.dart` |
| Preference providers | `providers/*_preferences_provider.dart` |
| Community settings | `presentation/guild_settings_modal.dart`, `domain/guild/guild_settings_tab.dart`, `presentation/pages/guild/`, `providers/guild/`, `data/` |
| Personas page; quick-switcher switch (fork) | `presentation/widgets/user_persona_settings.dart`; `providers/quick_switcher_button_preferences_provider.dart` |
| Widget kit (`FluxerSettingsSheet`, `FluxerSettingsSection`) | `lib/features/ui/settings/` |

## Reaching a section

User settings have no go_router routes: everything goes through `UserSettingsModal.show(context,
{initialSection, initialFieldId, sectionOnly, …})`.

- **Phones** (`isMobileLayout`): a root `FluxerPageSheet` with the searchable list
  (`_MobileSettingsNavBody`); a section opens as a nested sheet (`_showMobileSettingsSection`).
  `sectionOnly` opens the section alone.
- **Wide layouts:** `showWideSettingsBottomSheet`, a sidebar and content (`_UserSettingsModalState`).
- Both build the page through `_buildUserSettingsSectionContent` (visibility gates, deep-link scope)
  and `_buildUserSettingsSectionBody`, one `switch` over `UserSettingsSection`.
- Deep links (`/settings/user?tab=…`) go through `openUserSettingsDeepLink` to the same `show`; the
  persona picker's "Manage" opens `UserSettingsSection.personas`.
- **Community settings** (`GuildSettingsModal.show`) are go_router routes on phones
  (`RoutePaths.guildSettingsPath`, `GuildSettingsPageShell`) and a sheet on wide layouts
  (`GuildSettingsTabBody`); tabs are `GuildSettingsTab`, shown by permission.

**Adding a user-settings section** (as the Personas page did):

1. A value in `UserSettingsSection`; a fork value goes last, under `// Fork values.` Nothing stores a
   section by its index.
2. A case in each exhaustive `switch`: `userSettingsSectionLabel`, `_buildUserSettingsSectionBody`,
   `userSettingsDeepLinkTabForPage`.
3. An entry in a `_userSettingsDesktopNav*` list (the wide sidebar; search takes the icon from there)
   and in `buildUserSettingsMobileNavGroups`.
4. The tab in `userSettingsTabLabel`, `_userSettingsTabTypes` and `mapUserSettingsDeepLinkToSection`.
5. Search finds every section by its label. A single setting also needs an entry in
   `_userSettingsSearchOptions`, or a field id in `knownUserSettingsFieldIdsForTab` for a tab in
   `_searchableTabs` with the same `sectionId` on its `FluxerSettingsSection` (which registers the
   scroll key). The Personas page has none.

## How a page reads and saves a value

- Most pages apply each change at once: a control watches a provider and calls its setter. A save bar
  appears only in a `FluxerSettingsSheet` given `onSave` and `onReset`: the profile page (its sheet is
  built in the section `switch` from `UserSettingsViewModel`'s `edited*` state), the Personas page's
  display tag, an application's details.
- A phone's section sheet refuses to close only while `userSettingsViewModelProvider.isDirty`
  (`canDismissNotifier`, for every section); wide layouts change section without a check. Unsaved
  state kept anywhere else is dropped silently.

Where the value is kept decides who sees it:

| Store | Examples | Other devices |
|---|---|---|
| User settings, `PATCH /users/@me/settings` | `UserSettingsViewModel` setters (compact mode, embeds, developer mode…), `UserSettingsSyncService` (theme, time format, AFK, locale) | yes; mirrored in Drift |
| Synced preferences | setters calling `markDirty(SyncedPreferenceField.x)` or `ref.markSyncedDirty`: sound, double-tap, swipe, voice prompts, parts of appearance and advanced | yes |
| Drift `user_preferences`, per account | appearance, chat, advanced, voice, default apps (`load(userId)` at start-up, `_persist()` on change) | no, unless the setter also marks a synced field |
| SharedPreferences | notifications, haptics, open communities to last channel, the quick-switcher switch | no; shared by every account on the device |
| Persona settings, `PATCH /users/@me/personas/settings` | the Personas page | yes |

`AppearancePreferences` persists every setter to Drift, then marks `accessibility`,
`accessibilityOverrides`, `sidebar` or `privacy` dirty, or nothing (`setShowNeko`). A synced setter
must not mark dirty while applying a remote value (`_isApplyingRemote`).

**The fork's synced appearance fields:** `LookAndFeelMessagesSection` writes the chat font size
(`ThemePreference.setChatFontSize`) and message spacing (`setMessageGroupSpacing`) to the fork's
`mobile_*` accessibility fields, so phone and desktop keep their own; `applySyncedAccessibility` keeps
the local spacing when a blob lacks them. "Show alt text on images" is upstream mobile's setting; its
field number is moving back to upstream's (tyne-chat/tyne#146).

## The Personas page

`UserPersonaSettings` holds only the unsaved display tag; the rest is the profile folder's providers,
whose values are a server resource mirrored in SharedPreferences.

- **Mode** (`manual`, `last`) and **scope** (`global`, `channel`): radio groups calling
  `activePersonaProvider.notifier.setMode` / `setScope`, applied at once.
- **Display tag** (text up to 32 characters and an icon, with a preview), behind the save bar:
  `_tagTextController` and `_pendingTagIcon`, compared by `_computeIsDirty`, saved by
  `systemDisplayTagProvider.notifier.updateDisplayTag`. The icon is uploaded when picked, after
  `isImageOverUploadLimit`, uncropped, as `data:image/png` whatever the file; the returned
  `avatar_hash` waits for Save.
- **List:** `sortedPersonasProvider`, searched on the device by name, pronouns, bio and tags. "Make
  active" / "Active" (`setActivePersona`, `unlatch`) only with the global scope. Add and edit open the
  profile folder's `EditPersonaSheet`, which sends every field: pass the whole persona
  (`persona.toPublicPersona()`). Delete is a raw `DELETE`, then `removePersona`, and `unlatch()` if it
  was the selection.
- The web's page (tyne-chat/tyne `fluxer_app/src/features/persona/`) also imports from PluralKit,
  exports, and rolls failed changes back with a toast; mobile does none of these.

Known gaps (tyne-chat/tyne#156): an unsaved tag is lost when the sheet closes or the section changes. The `ref.listen` meant
to refresh the form tests `_isDirty`, which already reads the new value, so a tag changed elsewhere
shows as an unsaved change holding the old one, and Save writes it back. A failed list load shows the
empty state, with no error or retry. Every card is built (a `Column`, not a lazy list).
`_confirmDeletePersona` uses `ref` after the `DELETE` without checking `mounted`.

## Other fork changes and where they hook in

- **Registration:** `personas` last in the enum, one case in each `switch` named above, the last entry
  of the "your account" lists, the tab in the deep-link set.
- **Updater** (`user_settings_modal.dart`, Android only): a "Check for updates" item through a new
  `onCheckForUpdates` parameter on upstream's `buildUserSettingsMobileNavGroups`; a link in
  `_SettingsBuildInfoFooter`, whose returns became `Column`s; two identical check methods; a
  `ref.listen(appUpdateProvider)` in `_MobileSettingsNavBodyState.build` that toasts the result, so
  wide layouts get none. A fork widget and listener handed one line each would shrink these edits in
  upstream's most-changed file here.
- **Push clean-up:** both `_logout` methods await `forkPushSignOutCleanupProvider` before upstream's
  invalidations, which reset the user id it reads.
- **Quick-switcher button:** a `Notifier<bool>` over the SharedPreferences key
  `show_quick_switcher_button`, loaded in `main.dart`; its switch is first in the "Chat" section of
  `user_advanced_settings.dart`. The composer reads it; the sidebars' `QuickSwitcherFab` does not.
- **Profile page** (`user_profile.dart`, `profile_preview_card.dart`, inside upstream's functions):
  accent colour defaults to the avatar's (`_defaultProfileAccentColor`); bio length from
  `instanceLimitProvider(LimitKeys.maxBioLength)`; image size by `isImageOverUploadLimit`
  (`lib/shared/utils/fork_image_upload_limit.dart`), also in `application_detail.dart` and
  `guild_overview_widget.dart` (tyne-chat/tyne#110).
- **Two time-zone controls:** the fork's `_buildTimezoneSection` (`kTimezoneOptions`, in
  `features/chat/utils/timezone_data.dart`) and upstream's later `ProfileLocalTimeSettingsSection` both
  call `vm.updateTimezone`; the fork's ignores `needsKnownEmailVerification`, and its `isDirty` line
  repeats upstream's. Which stays is a maintainer's decision (root `AGENTS.md`).
- **Community emojis A to Z:** `compareGuildEmojiSettingsEntriesByName` appended to
  `guild_emoji_settings_entry.dart`; `_forkSortedByName` appended to `guild_emoji_settings_provider.dart`
  and used at upstream's two `_sortNewestFirst` calls and after an update; upstream's helper stays under
  `// ignore: unused_element`.

## Other traps

- A new upstream `switch` over `UserSettingsSection` does not compile until it has a `personas` case.
- Staff-only sections (developer tools, limits, feature flags) show when `AppBuildConfig.isCanary`;
  Tyne builds as canary (`tool/dart_defines/canary.json`), so every user sees them
  (tyne-chat/tyne#156).
- `services/premium_store_purchase_client.dart` is overwritten by `tool/configure_build.dart` from its
  `.stub.dart` or `.billing.dart` variant: edit the variants.

## Network calls

| Action | Requests | On failure |
|---|---|---|
| Opening the Personas page | none (its providers load at start-up and READY) | |
| Mode, "Make active", "Active" | 1 `PATCH /users/@me/personas/settings` | state stays; the error escapes unhandled (`unawaited` inside a `try`) |
| Scope | 1 `PATCH` | put back silently |
| Display tag Save | 1 `PATCH` | logged; the provider keeps the value, so it looks saved |
| Tag icon picked | 1 `POST /users/@me/personas/avatar` | logged |
| Delete persona | 1 `DELETE`, +1 `PATCH` if it was the selection; the delete event then reloads the list once per mobile session | logged; the persona stays |
| Profile Save | `PATCH /users/@me`, then `GET /users/@me` | error shown; edits kept |
| A user-settings toggle | 1 `PATCH /users/@me/settings` | reverted, rethrown |
| A synced preference | none here; the store sends a debounced `PATCH` | |
| Check for updates | 1 GitHub releases request | reported as up to date |

Each request answers a tap; nothing runs per item or per build, and the pages retry nothing.

## Tests

- `test/features/settings/`: upstream's page tests at the top level, then `providers/`, `utils/`,
  `data/`, `domain/`, `presentation/widgets/`.
- Fork, in the root `AGENTS.md` list: `presentation/widgets/user_persona_settings_test.dart` (render,
  search, latch, delete, display-tag dirty, reset and save, mode, icon removal). Its Dio answers `{}` to
  everything and the persona notifiers are fakes, so it neither counts nor fails a request. Also
  `test/core/deep_links/user_settings_deep_link_fork_test.dart`, through `test/core`.
- Fork, not in the list: `providers/quick_switcher_button_preferences_provider_test.dart`,
  `test/shared/utils/fork_image_upload_limit_test.dart` (tyne-chat/tyne#132). Upstream's
  `providers/guild/guild_emoji_settings_provider_test.dart`, whose expected order the fork changed
  under `// Fork:`, is not in it either.
- Not covered: a failed save, upload, delete or `PATCH`; request counts; a remote tag change; the
  accent default, the fork's time zone, the instance bio limit.
- After a change: the root list, `flutter test test/features/settings`, and the image-limit test if
  image checks changed.
