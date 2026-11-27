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

`tyne-mobile` is rebased onto `upstream` every night. Before editing an upstream-owned file, state
in one line where the change goes and why it cannot live in a fork-owned file or an appended block.

**Prefer, in this order:** (1) a new fork-owned file; (2) a block appended at the end under a fork
comment; (3) one small call or line handing over to fork code. Rewriting upstream lines is last
resort.

Mechanical rules (enforced where possible by the placement/safety lints):

- **Tests:** go in `<upstream name>_fork_test.dart` next to upstream's test; never add tests or
  assertions to an upstream test file (compile fixtures with `// Fork:` are the only exception).
  Export private helpers needed by fork tests in a block appended after `main` (`forkUpstream`
  record for functions, aliases with `// ignore: unreachable_from_main // Fork: used by ...`),
  imported with `hide main` (`message_dao_test.dart` / `message_dao_fork_test.dart`). Hardcoded
  upstream hosts in upstream test assertions must use `InstanceConstants` / `InstanceEndpoints`;
  other deliberate expectation changes need maintainer approval and a `// Fork:` comment.
- **Imports:** leave upstream imports untouched; add fork imports below under `// Fork imports.`
  before any `part` line (`// ignore: directives_ordering` / `// ignore_for_file: directives_ordering`
  only where the lint fires; keep unused upstream imports with `// ignore: unused_import // Fork: ...`,
  never `ignore_for_file`).
- **Formatting & ignores:** every Dart file runs `dart format`. Do not wrap upstream widgets in
  providers/parents, push signatures over the line limit, comment inside upstream expressions, or
  turn statements into cascades on upstream lines. Every `// ignore:` states why above or inline.
- **Lists & maps:** fork entries go first in upstream lists, maps and arguments unless order shows on screen.
- **Numbers upstream hands out:** never take upstream's next sequential value or insert into the middle.
  Protobuf fields `>= 2200` in the server schema's `// Fork fields.` block (`tyne`); no fork Drift
  schema version (declare columns with `// Fork:` and add on open in
  `lib/core/database/fork_schema.dart`, tested in `fork_schema_test.dart`); fork enum values last
  after `// Fork values.` (never stored/sent by `.index`); native markdown persona tag `255`
  (`decode_binary.dart`); fork catalogues/generated files never hand-edited.

When upstream ships an equivalent: same/superset -> take upstream's and delete ours; user-visible
difference -> stop and ask a maintainer. During rebase conflicts, move fork lines out of upstream's
and list moves; prefer plain edits over unasked plug-in layers.

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

Add all new user-facing strings (aligned with web wording) to `l10n_fork/fork_en.arb` and every
`l10n_fork/fork_*.arb`, run `bash tool/fork_l10n.sh`, read via `l10n.fork.<key>`
(`package:fluxer_app/l10n_fork/fork_localizations_x.dart`), and pass `flutter test test/l10n_fork`
plus `dart run tool/fork_string_lint.dart` (annotate intentional non-UI literals with
`// i18n-ignore: <reason>` and manually review strings passed across files). Never edit
`lib/l10n/*.arb` or `lib/l10n/generated/` (`l10n_fork/README.md`).

## Flutter and Riverpod rules

Enforced statically by `tool/fork_safety_lint.dart` and `tool/fork_async_ref_lint.dart`:

- **Never read `ref` or `context` in `State.dispose()`** (`dispose-ref`): cache providers/coordinators
  in `initState` and dispose through those fields.
- **Guard deferred callbacks and post-`await` reads** (`unmounted-listener`, `fork_async_ref_lint`):
  check `mounted` / `context.mounted` / `ref.context.mounted` or pre-capture `ref.container` before `await`.
- **Reset mutable fields in `@Riverpod(keepAlive: true)` `build()`** (`keepalive-reset`, or clear
  in unconditional top-of-`build()` `ref.onDispose()` / listeners); early-return guards must also
  verify subscriptions and initial data are actually live before short-circuiting.

## Fragile areas

- **Message list layout mutations** (`chat-layout` in `fork_safety_lint`): keep rows in
  `MessageListScrollViewBuildScope` (`message_list_viewport.dart`), use `RebuildSafeLayoutBuilder`
  (`lib/shared/widgets/`) in chat list/panel trees, and never mutate state synchronously in layout/scroll
  handlers; run `message_list_build_scope_test.dart` and `rebuild_safe_layout_builder_test.dart`.
- **Modals from message rows:** route row sheets/menus/media through `ForkMessageActionHost`
  (`lib/features/chat/AGENTS.md`).
- **Android IME insets:** replayed by `ForkMainActivity.kt` (`android/AGENTS.md`); describe UI
  behaviour as untested on device until verified.

## Network calls

Over 50 requests/s the server rejects a user's requests (`tyne`'s `AGENTS.md`). Code running per item,
in loops, in `build`, or from widely watched providers must share overlapping calls and never retry a
failure on rebuild (`build-network` in `fork_safety_lint`); add a request-counting test with missing
and failing responses as in `test/core/permissions/channel_effective_permissions_fork_test.dart`.

## Reviews, fixes and custom lints

Routine alongside every regression test: check whether a bug fix, post-mortem or audit finding has
an AST-detectable shape (or propose a rule on the issue). Add/tighten a pass in `tool/fork_lint.dart`
+ `tool/fork_lint/` (`safety_pass.dart`, `async_ref_pass.dart`, `string_pass.dart`; legacy
`tool/fork_*_lint.dart` wrappers delegate to the same pipeline) reusing `DartFileIR`: verify it fires
on the unfixed file (`git show <fix>^:<file>` for past bugs) and clears with the fix, add
positive/negative unit tests (`test/tool/`, `test/l10n_fork/`), sweep `--all` (proving real siblings
with failing tests, recording verified upstream semantic exceptions in `tool/fork_lint_reviewed.json`
with `--check-reviewed`, and refining AST precision to minimize suppressions), and keep enforced prose
here to one line.

## Before committing

Run the checks once the change is done (in the builder image, which has the pinned Flutter SDK and
Rust):

```bash
(cd packages/fluxer_markdown_native && dart test)
(cd packages/fluxer_markdown && flutter test)
(cd dart_sdk && dart test test/serialization/model_roundtrip_test.dart test/serialization/fork_model_roundtrip_test.dart)
flutter analyze lib test --no-fatal-warnings --no-fatal-infos
dart run tool/fork_lint.dart --upstream upstream/canary
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

Reviewed upstream `--all` lint exceptions go in `tool/fork_lint_reviewed.json` (`--check-reviewed`,
`--include-reviewed`), never as `*-ignore:` comments inside untouched upstream files. Changes under
`tool/fork_lint*` must also pass `dart run tool/fork_lint.dart --all --check-reviewed` and their
unit tests under `test/tool/` and `test/l10n_fork/`.
