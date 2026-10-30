# Server commands on the phone

Per-community slash commands (`/tuck`): typing `/` lists them, sending `/name input` runs one, and the
message shows a `/name` chip. Every file here is the fork's. What a command is and the rules are in the
server repository's `fluxer_api/src/api/guild_command/AGENTS.md`, and the design in its
`docs/design/server-commands.md`, "Mobile client". This guide is what the app does today: using
commands and showing the chip. There is no editor on phones yet, and tapping the chip does nothing.

## Where things are

| Concern | File |
|---|---|
| REST, through the SDK | `data/guild_commands_repository.dart` |
| Usable commands, precedence, loading, the `/` list | `providers/guild_commands_providers.dart` |
| Running `/name input` on send | `providers/guild_command_runner.dart`, called from `_forkRunGuildCommand` in `channel_textarea.dart` |
| The chip | `presentation/guild_command_chip.dart`, one child each in `message_item.dart`'s main row and compact prefix |
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
- **Use External Commands** is a constant, not a `Permission` value: upstream's switches over the enum
  are exhaustive, and the role editor that would list it is not on phones yet. `allPermissions` covers
  every bit for this; nothing sends it to the server.

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
- Do not turn Use External Commands into an enum value without the cases in upstream's exhaustive
  switches (`guild_role_permission_spec.dart`, `channel_permission_spec.dart`).
- `isRenderEquivalent` compares the command: without it, `MessageTileCache` keeps the old row after an
  edit removes the chip.
