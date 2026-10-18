# Tyne mobile: guide for agents and contributors

This is the Flutter client of [Tyne](https://github.com/tyne-chat/tyne), a fork of Fluxer's
[flutter_client](https://github.com/fluxerapp/flutter_client). This file is the shared guide for
coding agents (Claude Code, Antigravity and others) and for people working in this repository. The
maintainers keep machine-specific instructions (builder image, emulator, releases, approval rules)
outside the repository.

If you change something this file describes, update it in the same commit. Do not add a `CLAUDE.md`
or `GEMINI.md` to the repository: both tools read this file.

## Repositories and branches

- This repository, `tyne-chat/tyne-mobile`, works on branch `tyne`. It is rebased every night onto
  upstream's `canary` branch (remote `upstream`).
- `dart_sdk/` is a submodule: the Dart SDK generated from the server's OpenAPI spec
  ([tyne-chat/tyne-dart-sdk](https://github.com/tyne-chat/tyne-dart-sdk), branch `tyne`). Read
  `dart_sdk/AGENTS.md` before touching anything in it.
- `fluxer/` is a submodule holding the server monorepo; `packages/fluxer_markdown_native` builds its
  Rust markdown parser from there. In a clone where it is not checked out, the markdown package's
  tests fail with "Failed to launch cargo".
- The server, web and desktop apps are in [tyne-chat/tyne](https://github.com/tyne-chat/tyne). Its
  `AGENTS.md` covers the server side, personas, and the rules for issues, reviews and network calls
  that apply here too. All issues live on `tyne-chat/tyne`.
- iOS builds run in GitHub Actions and ship through TestFlight.

## Keep fork changes out of upstream's way

The fork is rebased onto upstream every night, and upstream restructures whole areas in a day. Every
fork line inside an upstream line is a future conflict. Before editing a file upstream owns, say in
one line where the change is going and why it cannot be a fork-owned file or an appended block.

**Prefer, in this order:** (1) a new fork-owned file; (2) a block appended to the end of an upstream
file, under a comment saying it is the fork's; (3) one small call or one added line in upstream's
code that hands over to fork code elsewhere. Rewriting or reordering upstream's lines comes last.

- **Tests** go in `<upstream name>_fork_test.dart` next to upstream's test. Never add a test or an
  assertion to an upstream test file (the exception: a fixture line upstream's test needs in order
  to compile against a fork type).
- **Upstream's private test helpers are not copied.** Dart cannot reach another file's private
  names, so append a block after `main` in upstream's test file that names the ones the fork test
  uses: a typed `forkUpstream` record for functions, `const`, typedef or getter aliases for the rest,
  each under `// ignore: unreachable_from_main // Fork: used by <fork test>.` The fork test imports
  upstream's file with `hide main` (`message_dao_test.dart` and `message_dao_fork_test.dart` show the
  shape). Exceptions: code inside upstream's `main` (`setUp` statements, local variables) cannot be
  named, so it is copied; a helper the fork needs in another shape is wrapped in the fork file around
  upstream's; and when upstream removes or reshapes a helper the block names, move a copy into the
  fork test instead of keeping the old version in upstream's file.
- **Upstream test expectations** that hard-code upstream's hosts must compare against
  `InstanceConstants` / `InstanceEndpoints`, so they hold for the fork's defaults. Other expectations
  where the fork deliberately differs may be changed in place with a `// Fork:` comment saying why,
  after asking a maintainer.
- **Imports:** leave upstream's imports exactly as upstream writes them. Fork imports go after them,
  under a `// Fork imports.` line (before any `part` line). When the analyzer flags the group's first
  import (`directives_ordering`), put `// ignore: directives_ordering` directly under
  `// Fork imports.`; when it flags several (`dart:` imports, or `package:` imports after upstream's
  relative ones in a test), use `// ignore_for_file: directives_ordering` there instead, under a
  `// Fork:` comment saying why. Add an ignore only where the lint fires: an unneeded one is itself
  reported (`unnecessary_ignore`).
- **Upstream imports the fork leaves unused** stay as they are. Ignore them per line, never with
  `ignore_for_file`, with the reason:
  `// ignore: unused_import // Fork: upstream's import, unused since the fork's changes.`
- **Formatting:** every Dart file is formatted (`dart format`), upstream's included. Place fork code so
  the formatter leaves upstream's lines alone: do not wrap upstream's code in a provider or a new
  widget (put a small fork widget in the place of one upstream call, or wrap from outside), do not
  lengthen upstream's signatures past the line limit, no comments inside upstream's expressions, and
  add fork behaviour as a separate statement rather than a cascade on upstream's expression. After
  formatting an upstream file, check that only fork lines moved.
- **An `// ignore:`** always has a comment above it (or after it) saying why.
- **Numbers upstream hands out** (protobuf fields, Drift schema versions, enum values, binary tags):
  never take upstream's next value or insert into the middle; the server repository's `AGENTS.md`
  has the rule and why. Here that means:
  - protobuf fields from 2200 up, in the `// Fork fields.` block at the top of the message;
  - no Drift schema version of the fork's own: a fork column or table is declared in its table class
    with a `// Fork:` comment and added on open by `lib/core/database/fork_schema.dart` (its comment
    explains why, and every fork column gets a test in `fork_schema_test.dart`);
  - fork values in an upstream enum go last, after a blank line and `// Fork values.`; Dart gives each
    value its position as `.index`, so an enum is never stored or sent by `.index`;
  - the persona mention's kind in the native markdown format is 255, the fork's range counting down
    (`packages/fluxer_markdown_native/lib/src/decode_binary.dart`, written by the server's parser).
- **Strings:** fork catalogues only (see "Translations").
- **Generated files:** never edited by hand (see "Generated code").

When upstream ships its own version of something the fork did: if it behaves the same or is plainly a
superset, take upstream's and delete ours; if it would change what people see or lose something ours
does, stop and ask a maintainer, describing both behaviours. In a rebase conflict, move fork lines
out of upstream's while resolving, and list the moves. Do not go overboard: if separating a change
needs more than a small hook, make the plain edit; if it needs real architecture, ask first.

## Generated code

Never edit generated code by hand; change its source and regenerate. Check the first lines of a file
before editing it: `GENERATED CODE - DO NOT MODIFY BY HAND`, `This is a generated file - do not edit`
or `@generated` means a tool rewrites it.

- **`dart_sdk/`**: generated from the server's OpenAPI spec, except `lib/gateway_client/` and
  `lib/gateway.dart`. The fix for a missing or wrong type is in the server's schema, followed by a
  regeneration (`dart_sdk/AGENTS.md`). For a quick experiment the app can reach the API without the
  SDK (`fluxerDioProvider` for REST, `UnknownGatewayEvent` for gateway events), but anything that
  ships goes through the schema. Fork helpers and wrappers go in the app, not in the SDK.
- **`*.g.dart`**: output of `dart run build_runner build --delete-conflicting-outputs`. Change the
  annotated source; for lenient decoding, write a `JsonConverter` on the field so the generator emits
  it. The files are not committed, so run the generator after pulling a rebased branch, before
  analyzing or testing.
- **Localisation output** (`lib/l10n/generated/`, `lib/l10n_fork/generated/`): see "Translations".
- **Synced preferences** (`lib/core/synced_preferences/generated/`): generated from the `.proto`
  files next to them in `lib/core/synced_preferences/proto/`, with the exact protobuf plugin version
  upstream uses, so the output for upstream's files stays byte-identical to upstream's.
- In a merge or rebase conflict on a generated file, take upstream's version and regenerate.
- Say in the commit or summary which generator ran. "I edited the model" is never a valid
  description of a change under `dart_sdk/lib/models`.

## Translations

New user-facing strings go into the fork catalogues, with real, idiomatic translations in every
language (aligned with the web app's fork catalogue where the same string exists):

1. Add the string to `l10n_fork/fork_en.arb` and to every other `l10n_fork/fork_*.arb`.
2. Run `bash tool/fork_l10n.sh`.
3. Use it as `l10n.fork.someKey` (import `package:fluxer_app/l10n_fork/fork_localizations_x.dart`).
4. `flutter test test/l10n_fork` must pass.

Never edit upstream's catalogues (`lib/l10n/*.arb`, `lib/l10n/generated/`). Details in
`l10n_fork/README.md`.

## Flutter and Riverpod rules

- **Never call `ref.read()` or `ref.watch()` in `State.dispose()`.** It throws `Bad state: Using "ref"
  when a widget is about to or has been unmounted is unsafe`, which stops Flutter's unmounting halfway
  and leaves orphaned elements that break later builds (`No ProviderScope found`, the
  `FluxerRenderErrorPlaceholder` "An error occurred" screen). Cache the provider or coordinator in a
  field in `initState` and clean up through that field in `dispose()`.
- **Guard route and stream listeners with `mounted`.** Listeners on routing or active-channel
  providers (`activeChannelIdProvider`, `chatViewModelProvider`) check `if (!mounted) return;` before
  reading providers.
- **Reset instance fields in kept-alive notifiers.** In a `@Riverpod(keepAlive: true)` notifier,
  `ref.invalidate(...)` re-runs `build()` on the same instance, so tracking fields (`_currentGuildId`,
  `_subscription`, caches) survive unless cleared in `build()`, `onDispose()` and user-change
  listeners. An early-return guard (`if (_currentGuildId == guildId) return;`) must check that the
  subscription and initial data are actually live before short-circuiting.

## Fragile areas

**Message list mutations during layout.** Changing state or notifying listeners while the message
list is mid-layout has caused frozen subtrees and wrong scroll positions. Read the existing guards and
use them rather than working around them:

- `lib/features/chat/presentation/widgets/messages/message_list.dart`
- `lib/features/chat/presentation/widgets/messages/message_list_viewport.dart`
  (`MessageListScrollViewBuildScope`, which keeps row builds from rebuilding the list's ancestors
  mid-layout)
- `lib/shared/widgets/rebuild_safe_layout_builder.dart` (instead of a bare `LayoutBuilder` inside the
  chat panel)

Their regression tests (`test/features/chat/presentation/widgets/messages/message_list_build_scope_test.dart`,
`test/shared/widgets/rebuild_safe_layout_builder_test.dart`) fail on purpose without the guard: run
them after touching this code, and add one when fixing a new case.

**Android keyboard (IME) insets.** Insets can go stale when the window loses and regains focus,
leaving the composer misplaced. The handling is split between
`android/app/src/main/kotlin/com/fluxer/MainActivity.kt` and
`lib/features/chat/presentation/widgets/pickers/chat_composer_column.dart`; change them together.
Unit tests cannot confirm it.

UI behaviour is verified on a device or emulator by a maintainer. Until then, describe such a change
as untested on device.

## Network calls

The server revokes a session that goes over 50 requests per second, so a burst of requests signs the
user out (details and the questions to answer before adding a call: the server repository's
`AGENTS.md`, "Network calls"). Code that runs per channel, message or member, in a loop, from a
widget's `build` or from a widely watched provider must share overlapping requests and must not retry
a failed one on the next build. Such a change needs a test that counts the requests with the data
missing and with the request failing, using a recording Dio adapter as in
`test/core/permissions/channel_effective_permissions_fork_test.dart`.

## Before committing

Run the checks once the change is done, as the gate before committing. They cover the same tests as
the nightly rebase gate, whose analysis step is stricter (below). They need the Flutter SDK this
project pins and Rust (for the markdown package); the maintainers run them in a builder image.

```bash
(cd packages/fluxer_markdown_native && dart test)
(cd dart_sdk && dart test test/serialization/model_roundtrip_test.dart test/serialization/fork_model_roundtrip_test.dart)
# Upstream's code carries warnings and infos, so only errors fail here (as in tool/flutter_analyze.sh).
flutter analyze lib test --no-fatal-warnings --no-fatal-infos
flutter test test/l10n_fork test/core test/features/chat test/features/profile test/features/quick_switcher test/features/ui/bottom_sheet test/features/ui/input test/features/settings/presentation/widgets/user_persona_settings_test.dart test/features/emoji/presentation/sheets/emoji_info_bottom_sheet_test.dart
```

The nightly gate's analysis step asks more of the fork's code than `flutter analyze` does, and checks
the working tree, untracked files included:

- every Dart file the fork added or changed is formatted (`dart format`);
- files the fork added, and the fork's lines in upstream's files, have no analyzer diagnostics at
  all, infos included;
- upstream's code is held to upstream's CI (formatted, no errors).

A few tests are skipped by the nightly gate, each tied to an audit finding that removes it. Never add
a test to that list to get a change through.
