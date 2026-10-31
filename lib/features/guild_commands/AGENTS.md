# Server commands on the phone

Per-community slash commands (`/tuck`): typing `/` lists them, sending `/name input` runs one, and the
message shows a `/name` chip. Every file here is the fork's. What a command is and the rules are in the
server repository's `fluxer_api/src/api/guild_command/AGENTS.md`, and the design in its
`docs/design/server-commands.md`, "Mobile client". This guide is what the app does today: using
commands, the chip, and the Commands tab of community settings.

## Where things are

| Concern | File |
|---|---|
| REST, through the SDK | `data/guild_commands_repository.dart` |
| Usable commands, precedence, loading, the `/` list | `providers/guild_commands_providers.dart` |
| Running `/name input` on send | `providers/guild_command_runner.dart`, called from `_forkRunGuildCommand` in `channel_textarea.dart` |
| The chip, its tap and long press | `presentation/guild_command_chip.dart`, one child each in `message_item.dart`'s main row and compact prefix |
| The chip's text reaching the composer | `pendingGuildCommandInsertProvider`, listened to in `channel_textarea.dart` |
| The Commands tab: list and editor | `presentation/guild_commands_settings.dart`, `guild_command_editor.dart`; registered as `GuildSettingsTab.commands` and `GuildAction.settingsCommands` |
| Who may edit, a chip opening a command | `providers/guild_command_editing.dart` |
| `command` on a message | three fields in `chat/domain/message.dart`, three columns in `core/database/tables/messages.dart`, added on open by `fork_schema.dart` |
| Grouping | a fork block in `chat/utils/messages/message_grouping_utils.dart` |
| `GUILD_COMMANDS_UPDATE` | `onGuildCommandsUpdate` in `core/gateway/gateway_event_handler.dart`, wired in `gateway_provider.dart` |

## How it works

- **Picking** a command inserts `/name ` as text: it is a `ComposerActionSlashCommand` with no options,
  so `_applyCommand` opens no slash session. The input is typed in the normal composer, where mentions,
  personas and emoji work; a string slot would not keep them, as on the web.
- **Sending:** `_onSendPressed` offers the text to `GuildCommandRunner` after upstream's edit and
  slowmode handling, so slowmode blocks a command like any message. Typed and pasted commands take the
  same path. The message arrives through the gateway like any other, so nothing is stored here.
- **A command sends only text:** staged attachments and an open reply stay.
- **Precedence:** built-ins, then the channel's community, then sidebar order (`usableGuildCommands`).
  Another community's commands need Use External Commands in a community channel; in DMs every
  community's work. The composer lists only the command each name runs.
- **The chip:** a tap puts `/name ` in an empty message box, if that command is the one `/name` runs
  in the channel; with text in the box, a toast says to clear it. A long press offers **Edit /name**
  to those who may change it (Manage Commands, or Create Commands for their own).
- **The editor** is a sheet over the list, as the persona editor is (`GuildCommandEditorSheet`), so
  Back returns to the list and unsaved changes keep it from being dragged away. A chip's long press
  opens it through `guildCommandEditRequestProvider` once the list is in. It uses
  `EmojiTextEditingController`, as the profile bio does: custom emoji show as
  emoji, `:` suggests them, and `actualText` is the stored `<:name:id>` form. A script opens read-only:
  it is written in the web or desktop editor, which previews through the server.
- **Permissions:** `createCommands`, `manageCommands` and `useExternalCommands` are fork values in
  `Permission`, with their labels in the role and channel editors. `allPermissions` covers every bit
  for them; nothing sends it to the server.

## Requests

- One `GET /users/@me/guild-commands` on first use (the `/` list, or a send starting with `/`), shared
  by every caller. The `/` list waits for it for at most 800 ms.
- `GUILD_COMMANDS_UPDATE` sends nothing: it marks the community stale, and the next use fetches that
  community. More than three stale communities are reloaded with the one list request. READY starts
  over, and so does another account.
- Joining and leaving are noticed at the next use, by comparing the sidebar with the last load.
- After a failed request nothing is asked for 30 seconds. A run sends one request, a second press while
  it is out sends none, and a retry of the same text keeps its nonce. A 404 marks the community stale.
- `test/features/guild_commands/` counts these with a recording Dio adapter.

## Traps

- Do not give a command options to get a hint or a slot UI without fixing what a slot loses:
  mentions typed into it (the design's "Mentions in the input").
- `isRenderEquivalent` compares the command: without it, `MessageTileCache` keeps the old row after an
  edit removes the chip.
