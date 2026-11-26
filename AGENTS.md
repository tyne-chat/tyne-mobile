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

## Architecture and folder guides

`ARCHITECTURE.md` describes how the app is put together (layers, start-up, state, the main flows, where
the fork plugs in) and lists the folders that have an `AGENTS.md` of their own. Read it before a change
that crosses folders, and read a folder's `AGENTS.md` before changing code under it: some tools load it
only when they open a file there, others never do. Keep both up to date as you would this file.

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
- **Upstream's private test helpers are not copied.** Append a block after `main` in upstream's test
  file naming what the fork test uses (`forkUpstream` record for functions, `const`/typedef/getter
  aliases for the rest, each under `// ignore: unreachable_from_main // Fork: used by <fork test>.`),
  and import with `hide main` (see `message_dao_test.dart` / `message_dao_fork_test.dart`). Copy
  code inside `main` (`setUp`, locals), wrap helpers needed in a new shape in the fork file, and if
  upstream removes or reshapes a named helper, move a copy into the fork test rather than keeping the
  old version in upstream's file.
- **Upstream test expectations** hard-coding upstream's hosts must compare against
  `InstanceConstants` / `InstanceEndpoints`. Other deliberate differences may be changed in place
  with a `// Fork:` comment after asking a maintainer.
- **Imports:** leave upstream's imports untouched. Fork imports go below them under `// Fork imports.`
  (before any `part` line). Put `// ignore: directives_ordering` directly under `// Fork imports.`
  when the first import is flagged, or `// ignore_for_file: directives_ordering` under a `// Fork:`
  comment when several are (`dart:` imports, or `package:` after relative in tests). Add ignores
  only where the lint fires (`unnecessary_ignore` fails too).
- **Upstream imports the fork leaves unused** stay; ignore per line (never `ignore_for_file`):
  `// ignore: unused_import // Fork: upstream's import, unused since the fork's changes.`
- **Formatting:** every Dart file is formatted (`dart format`), upstream's included. Keep upstream's
  lines unmoved: do not wrap upstream's widgets in a provider or parent widget (swap one call for a
  small fork widget, or wrap from outside), do not push signatures past the line limit, put no
  comments inside upstream's expressions, and add fork behaviour as a separate statement rather than
  a cascade. Check after formatting that only fork lines moved.
- **An `// ignore:`** always has a comment above it (or after it) saying why.
- **Lists and objects:** fork entries go first in upstream's lists, maps and argument lists, not
  last where upstream appends, unless the order shows on screen.
- **Numbers upstream hands out** (protobuf fields, Drift schema versions, enum values, binary tags):
  never take upstream's next value or insert into the middle; the server repository's `AGENTS.md`
  has the rule and why. Here that means:
  - protobuf fields from 2200 up, in the `// Fork fields.` block at the top of the message, in the
    server's schema (tyne), which the app's protobuf files are generated from;
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
- **Time zone menu data** (`lib/features/chat/utils/timezone_menu_data.dart`): generated by the
  maintainers' `gen_timezone_menu.py` from an IANA tzdata release. Keep that release on the one the
  `timezone` package ships, and regenerate when the package moves.
- **Synced preferences** (`lib/core/synced_preferences/generated/`): generated by upstream's
  `tool/generate_protos.sh` from the server's schema in the `fluxer` submodule
  (`packages/schema/proto/` in tyne), so the fork's fields come from the server's fork blocks. The
  `.proto` files in `lib/core/synced_preferences/proto/` are upstream's and no longer read; the fork
  does not change them (`lib/core/synced_preferences/AGENTS.md`).
- **Desktop plugin registrants** (`generated_plugin*` in `linux/flutter/` and `windows/flutter/`,
  `macos/Flutter/GeneratedPluginRegistrant.swift`): written by `flutter pub get`; the nightly
  rebase moves them into its tip commit.
- In a merge or rebase conflict on a generated file, take upstream's version and regenerate.
- Say in the commit or summary which generator ran. "I edited the model" is never a valid
  description of a change under `dart_sdk/lib/models`.

## Translations

New user-facing strings go into the fork catalogues, with real, idiomatic translations in every
language (aligned with the web app's fork catalogue where the same string exists). Never write
user-facing text as a plain string, not even a toast, an error message, a tooltip or a fallback
"for now": add the key and its translations in the same change. Untranslated strings that slipped in
are the reason for step 5's lint.

1. Add the string to `l10n_fork/fork_en.arb` and to every other `l10n_fork/fork_*.arb`.
2. Run `bash tool/fork_l10n.sh`.
3. Use it as `l10n.fork.someKey` (import `package:fluxer_app/l10n_fork/fork_localizations_x.dart`).
4. `flutter test test/l10n_fork` must pass.
5. `dart run tool/fork_string_lint.dart` must pass. It reports string literals on the fork's lines in
   places people read them (`Text(...)`, named arguments such as `label:`, `message:` or
   `errorMessage:`, toasts and error dialogs), which step 4 cannot see because they never reach a
   catalogue. A literal that really is not translated (a brand name, a process name, a debug
   screen) gets `// i18n-ignore: <reason>` on its line or the line above. It follows no variables:
   text built in one place and shown in another still needs your eye.

Never edit upstream's catalogues (`lib/l10n/*.arb`, `lib/l10n/generated/`). Details in
`l10n_fork/README.md`.

## Flutter and Riverpod rules

- **Never call `ref.read()` or `ref.watch()` in `State.dispose()`.** It throws `Bad state: Using "ref"
  when a widget is about to or has been unmounted is unsafe`, which stops Flutter's unmounting halfway
  and leaves orphaned elements that break later builds (`No ProviderScope found`, the
  `FluxerRenderErrorPlaceholder` "An error occurred" screen). Cache the provider or coordinator in a
  field in `initState` and clean up through that field in `dispose()`.
- **Guard route, stream, and post-`await` reads.** Listeners on routing or active-channel providers
  (`activeChannelIdProvider`, `chatViewModelProvider`) check `if (!mounted) return;`, and `async`
  widget code must pre-capture providers before `await` or check `mounted` / `context.mounted` /
  `ref.context.mounted` (`tool/fork_async_ref_lint.dart`).
- **Reset instance fields in kept-alive notifiers.** In a `@Riverpod(keepAlive: true)` notifier,
  `ref.invalidate(...)` re-runs `build()` on the same instance, so tracking fields (`_currentGuildId`,
  `_subscription`, caches) survive unless cleared in `build()`, `onDispose()` and user-change
  listeners. An early-return guard (`if (_currentGuildId == guildId) return;`) must check that the
  subscription and initial data are actually live before short-circuiting.

## Fragile areas

**Message list mutations during layout.** Changing state or notifying listeners mid-layout has
caused frozen subtrees and wrong scroll positions. Use the existing guards:

- `lib/features/chat/presentation/widgets/messages/message_list.dart`
- `lib/features/chat/presentation/widgets/messages/message_list_viewport.dart`
  (`MessageListScrollViewBuildScope`, keeping row builds from rebuilding ancestors mid-layout)
- `lib/shared/widgets/rebuild_safe_layout_builder.dart` (instead of bare `LayoutBuilder` in chat)

Run `test/features/chat/presentation/widgets/messages/message_list_build_scope_test.dart` and
`test/shared/widgets/rebuild_safe_layout_builder_test.dart` after touching this code, and add a
test when fixing a new case.

**Modals opened from message rows.** Keyboard hide and `READY` re-anchoring increment `_anchorEpoch`
and unmount every `MessageItem` while modals stay open; route row-opened sheets, menus, and media
actions through `ForkMessageActionHost` (`lib/features/chat/AGENTS.md`).

**Android keyboard (IME) insets.** Insets can go stale on window focus transitions; `ForkMainActivity.kt`
replays them (`android/AGENTS.md`), and the Dart side is upstream's (`lib/features/chat/AGENTS.md`).
UI behaviour is verified on a device or emulator by a maintainer; describe it as untested on device
until confirmed.

## Network calls

Over 50 requests/s the server refuses a user's requests on all devices (`tyne`'s `AGENTS.md`,
"Network calls"). Code running per channel, message or member, in a loop, from `build`, or from a
widely watched provider must share overlapping requests and never retry a failure on the next build.
Add a request-counting test (with missing data and failing requests) using a recording Dio adapter as
in `test/core/permissions/channel_effective_permissions_fork_test.dart`.

## Before committing

Run the checks once the change is done (in the builder image, which has the pinned Flutter SDK and
Rust):

```bash
(cd packages/fluxer_markdown_native && dart test)
(cd packages/fluxer_markdown && flutter test)
(cd dart_sdk && dart test test/serialization/model_roundtrip_test.dart test/serialization/fork_model_roundtrip_test.dart)
flutter analyze lib test --no-fatal-warnings --no-fatal-infos
dart run tool/fork_string_lint.dart --upstream upstream/canary
dart run tool/fork_async_ref_lint.dart --upstream upstream/canary
dart run tool/fork_safety_lint.dart --upstream upstream/canary
flutter test test
flutter build apk --config-only && mkdir -p build/app/intermediates/flutter/canaryUnifiedpushDebug && (cd android && ./gradlew :app:testCanaryUnifiedpushDebugUnitTest -x :app:compileFlutterBuildCanaryUnifiedpushDebug --tests 'com.fluxer.Fork*' --tests 'com.fluxer.*ForkTest' --tests 'com.fluxer.AppInstallBridgeTest')
```

The nightly gate's analysis step asks more of the fork's code than `flutter analyze` does, and checks
the working tree, untracked files included:

- every Dart file the fork added or changed is formatted (`dart format`);
- files the fork added, and the fork's lines in upstream's files, have no analyzer diagnostics at
  all, infos included;
- upstream's code is held to upstream's CI (formatted, no errors).

The nightly gate skips no test; never skip or weaken one to get a change through.
