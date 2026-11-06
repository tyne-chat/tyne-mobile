# The Android host

The Gradle project that wraps the Flutter app: the build script, the manifests, the resources and about
twenty small Kotlin classes in package `com.fluxer`, most of them bridges that each give Dart one
platform capability. It is upstream's project. The fork ships one variant, `canaryUnifiedpush` in
release mode, as Tyne: its own application ID, link scheme and artwork, plus an APK installer bridge for
the in-app updater, a keyboard inset fix in `MainActivity` and an extra push library.

## Where things are

Kotlin files are in `app/src/main/kotlin/com/fluxer/`.

| Concern | File |
|---|---|
| Flavours, application IDs, manifest placeholders, signing, dependencies | `app/build.gradle.kts` (plugin versions: `settings.gradle.kts`) |
| Permissions, activities, link filters, launcher aliases, services | `app/src/main/AndroidManifest.xml`; per variant `app/src/{canary,debug,profile,fcm,unifiedpush}/` |
| Tyne's launcher and notification icons (fork) | `app/src/canary/res/` |
| The activity, bridge registration, OAuth link deferral, the inset fix | `MainActivity.kt` |
| Process start: Measure, stale Firebase alarms | `FluxerApplication.kt` |
| Reply from a notification without starting Flutter | `NotificationReplyBridge.kt`, `FluxerNotificationReplyReceiver.kt`, `NotificationReply.kt`, `HttpNotificationReplyPoster.kt`, `SecureAuthTokenReader.kt` |
| SSO return, Custom Tab clean-up | `SsoCallbackActivity.kt`, `SsoAuthSessionTasks.kt`, `InAppBrowserTasks.kt` |
| APK installer (fork) | `AppInstallBridge.kt`, `app/src/main/res/xml/file_paths.xml` |

## Variants and identity

- **Flavours:** `environment` (`stable`, `beta`, `canary`) times `push` (`fcm`, `unifiedpush`). Only
  `canary` is Tyne; `stable` and `beta` keep upstream's `com.fluxer` and are not shipped. Upstream's
  `CONTRIBUTING.md` ("Mobile builds") explains them, with upstream's IDs.
- **The `canary` flavour** (`app/build.gradle.kts`): `applicationId = "chat.tyne.app"` (upstream:
  `com.fluxer.canary`), `appLabel` "Tyne", `deepLinkScheme` `tyne` (`defaultConfig`: `fluxer`). Inside the
  app, the default product name is `FORK_APP_NAME` in `tool/dart_defines/canary.json`.
- **`namespace = "com.fluxer"`** is the Kotlin package and the `R` class; the manifest's `.MainActivity`
  resolves against it. It is not the application ID; leave it.
- **Flavour and Dart defines must agree:** `--flavor canaryUnifiedpush
  --dart-define-from-file=tool/dart_defines/canary.json --dart-define=PUSH_PROVIDER=unifiedpush`.
  Gradle picks the manifest meta-data and Firebase libraries from the flavour, Dart its push service from
  `PUSH_PROVIDER` (`lib/core/build/app_build_config.dart`), which `canary.json` does not set. Nothing
  fails at build time: a missing value only prints a debug warning, a mismatched one nothing.
- **Ignored local files the build reads:** `key.properties` (release signing),
  `app/google-services.json`, and `measure.properties` or `local.properties` (Measure keys).

## Bridges to Dart

`MainActivity.configureFlutterEngine` registers them. Channel and method names are strings on both
sides: a rename on one side compiles and fails only at run time (`MissingPluginException` or
`notImplemented`), which several Dart callers swallow.

| Channel `fluxer_app/…` | Kotlin | Dart, in `lib/` |
|---|---|---|
| `app_install` (fork) | `AppInstallBridge` | `app_update_service.dart` |
| `browser_launch` | `BrowserLaunchBridge` | `platform_browser_launcher.dart` |
| `android_animator_duration_scale` (event) | `AnimatorDurationScaleBridge` | `android_animator_duration_scale.dart` |
| `physical_keyboard` (event) | `PhysicalKeyboardBridge` | `physical_keyboard.dart` |
| `notification_reply` | `NotificationReplyBridge` | `android_notification_reply_bridge.dart` |
| `voice_speaker_route` | `VoiceSpeakerRouteBridge` | `voice_speaker_route.dart` |
| `app_restart` | `AppRestartBridge` | `android_app_restart.dart` |
| `upload_keep_alive` | `UploadKeepAliveBridge` | `upload_keep_alive.dart` |
| `ime_editing_shortcut` (Kotlin calls Dart) | `ImeEditingShortcutBridge` | `text_editing_shortcuts.dart` |
| `measure_reporting` | `MeasureReporting` | `measure_native_reporting.dart` |

`fluxer_app/android_notifications` belongs to `packages/fluxer_android_notifications`; the other
`fluxer_app/…` channels in `lib/` are iOS-only. Also shared by string: the drawable
`fluxer_logo_monochrome` (Kotlin, the `fcm` manifest, Dart's `kAndroidPushNotificationIcon`, `keep.xml`),
the notification channel `fluxer_messages`, and the secure-storage keys of `auth_token_storage.dart`,
which `SecureAuthTokenReader` reads with its own copy of `flutter_secure_storage`'s options.

**Only the activity's engine has them.** A push that finds Tyne not running is handled in
`FluxerUnifiedPushService`'s own engine (`main` with `--unifiedpush-bg`), where none of these channels
exist. The full app can also start before the activity exists, in audio_service's engine, which
`MainActivity` (an `AudioServiceActivity`) attaches to later. Until then its start-up calls to these
channels fail. Up to 2026-10-23 that happened on every such push, because audio_service's plugin
starts its media service from any engine it is attached to, and that service starts the full app. Then
Measure could not start, and the crash-report prompt took Android ending the process for a crash
(tyne-chat/tyne#210).

The push engine is now a `ForkPushEngine`:
- It registers no plugin by itself, so upstream's explicit `GeneratedPluginRegistrant.registerWith` is
  the only registration. `FlutterEngine(context)` used to register every plugin a second time; logcat
  showed `already registered` for each.
- It leaves `AudioServicePlugin` out of that registration.
- It empties the UnifiedPush plugin's replay of recent calls when it starts (tyne-chat/tyne#474).
  Otherwise its plugin replays pushes the main app already handled, and they would be shown again.

To check it on a phone, end Tyne in the background with `adb shell am kill chat.tyne.app`, then send it
a push. Don't use `force-stop`: Android delivers no pushes to a force-stopped app. The push must
produce its notification, with no `MediaBrowserCompat: Connecting` line, no
`MediaSessionStack: addSession ... chat.tyne.app` and no `[Measure] Native SDK is not configured` in
logcat.

**Background pushes** (tyne-chat/tyne#474). Upstream's notifications rewrite (`f2aa9e49b`,
2026-11-04) now does what the fork's own fix for #474 did: a push that arrives while the app is not
on screen opens a push *session* (a started foreground service, a wake lock, a counted ledger), and
the session ends when Dart reports it has handled every push it was given. The fork keeps two
things upstream does not do (a fork block at the end of `FluxerUnifiedPushService.kt`'s companion):

- **The push engine is never destroyed while an app engine exists**, the activity's or
  audio_service's cached one: shared_preferences_android keeps one process-wide registration that
  every engine's attach overwrites and any engine's detach removes. Destroying the push engine then
  left the app without preferences, stuck at its launch screen (2026-11-02, build 170). Upstream
  destroys it at the end of every session. In the fork, once an app engine has started, a session's
  end keeps the engine (and its ledger, which counts over the engine's life as Dart's handled count
  does); the next session reuses it.
- **An idle push engine goes before the app's engine registers its plugins**
  (`forkBeforeAppEngine()`, called first in `MainActivity.onCreate`), while that is still safe.
- `ForkPushEngine` empties the UnifiedPush plugin's replay when it starts (above).

Known differences from the fork's earlier fix, left as upstream has them until tested on a phone:
the wake lock is taken after the hop to the main thread, not at once on the connector's thread; a
push goes to the app's engine only while the app is visible; and on a kept engine, Dart reports
that it is idle only once, so later sessions end on upstream's 30 s limit rather than at once.

**To check it:** run `am kill`, then send a burst of pushes. Expect a notification post for every
push, no `ForegroundServiceDidNotStartInTimeException`, and no `fluxer:unifiedpush` wake locks in
`dumpsys power` once the burst is done. Then open the app while a push session is open, and again
after one ended: it must reach the chat list, not stay at its launch screen.

**Reply from a notification:** Dart posts the notification, then `attachAndroidNotificationReply` has
Kotlin add a reply action to it. On reply, `FluxerNotificationReplyReceiver` reads the account's token
and API base from secure storage and `HttpNotificationReplyPoster` posts to `/channels/{id}/messages`
under a 30-second wake lock, without starting Flutter. The fork's first body field,
`"use_persona_selection":true`, has the server send it as the persona selected in that channel, or the
one a tag in the text names, since this code cannot see the app's selection (tyne-chat/tyne#343; Dart's
reply path for iOS sends the same).

## The fork's changes and where they sit

| Change | Where and how |
|---|---|
| ID, label, link scheme | `canary` flavour and `defaultConfig` in `app/build.gradle.kts`, under `// Fork:` comments; `${deepLinkScheme}` in the seven `<data>` lines of the manifest's custom-scheme filter |
| Artwork | fork-owned, generated files in `app/src/canary/res/` that replace `main`'s by resource name (`drawable/fluxer_logo_monochrome.xml` points at `tyne_notification_glyph`); do not edit them by hand. One upstream line changed: the colour in `values/ic_launcher_background.xml` |
| APK installer | fork-owned `AppInstallBridge.kt` and `file_paths.xml`; a `REQUEST_INSTALL_PACKAGES` line; the `FileProvider` appended to `<application>` (no fork comment); registered first in `configureFlutterEngine` |
| Push engine without audio_service (tyne-chat/tyne#210) | fork-owned `ForkPushEngine.kt`, created by one line in `FluxerUnifiedPushService.createBackgroundEngine` (below) |
| Push engine kept while the app's engine exists (tyne-chat/tyne#474) | a fork block at the end of `FluxerUnifiedPushService.kt`'s companion, reached by one `// Fork:` line in `closeBackgroundSession`; one line in `MainActivity.onCreate`; `ForkPushEngine`'s replay reset |
| Keyboard inset fix | in `MainActivity.kt`, unmarked: `onWindowFocusChanged`, `insetResync`, `scheduleInsetResync`, `resyncFlutterInsets`, two companion constants, a line in `onDestroy`, five imports in upstream's list |
| Push library | `embedded-fcm-distributor` for every flavour, its keep rule last in `app/proguard-rules.pro`, and the google-services plugin applied whenever `app/google-services.json` exists (upstream: `fcm` tasks only) |
| SDK level | `compileSdk = 37` in place of Flutter's value, with null-safe `taskInfo` in `InAppBrowserTasks` and `SsoAuthSessionTasks`; nothing records why |

Upstream changes the main manifest, `MainActivity.kt` and `app/build.gradle.kts` most, so rebase
conflicts land there; keep the lines above. New fork work: Kotlin in a fork-owned class reached by one
line (Kotlin has no fork-imports rule, and this keeps imports out of upstream's files), resources in the
`canary` source set or under fork names, manifest entries at the end of `<application>` under
`<!-- Fork: … -->`, Gradle lines under `// Fork:`. The inset fix would conflict less as such a class.

## The keyboard inset fix

- **Problem:** on API 30 and later, Flutter's `ImeSyncDeferringInsetsCallback` holds window insets while
  a keyboard animation runs and dispatches them when it ends. Switching apps mid-animation can cancel it
  without that dispatch, leaving Flutter laid out for a keyboard that is gone: the composer raised over
  a blank band.
- **Fix:** on each window focus gain, `MainActivity` posts `insetResync` 500 ms later (a new post
  replaces a pending one; `onDestroy` removes it). If the keyboard is not visible, it passes the view's
  root insets to `flutterView.onApplyWindowInsets` directly, past the stuck listener, and logs
  `FluxerInsets` at debug level. It runs on every focus gain (dialogs, the notification shade, returning
  to the app).
- **Dart side:** no channel. The engine's metrics change and upstream's `ChatComposerColumn` passes them
  on through `didChangeMetrics` (`lib/features/chat/AGENTS.md`, "The composer"). The fork's only Dart
  change there is the `_logResumeInsets` debug log.
- **Check on a device** with Android 11 or later: keyboard to panels and back, the notification shade,
  switching apps while the keyboard opens.

## Traps that break installs and releases without a conflict

- **The application ID `chat.tyne.app` is permanent:** Android treats a new ID as another app, installed
  next to the old one, signed out. The `FileProvider` authority derives from it on both sides.
- **So is the signing key:** Android refuses an update signed with another key, and the passkey files
  name the certificate (below).
- **A release build without `key.properties` is signed with the committed debug key**, without a
  warning. It installs on a clean phone but cannot update a release install; check the signer
  (`apksigner verify --print-certs`) of any APK meant for users.
- **Debug builds share the application ID** and use the debug key: a debug `canary` build cannot replace
  a release install without uninstalling it, which deletes its data.
- **The version code** is Flutter's build number: `--build-number`, or else the `+1` in `pubspec.yaml`.
  Android refuses an update with a lower code; the in-app updater compares the version name and build
  number with the release tag (`lib/core/updater`).
- **The in-app updater checks what it installs** (`lib/core/updater`, `AppInstallBridge.kt`): only an
  asset under `https://github.com/tyne-chat/tyne-mobile/releases/download/` with GitHub's `sha256:`
  digest is offered, the download must match its size and digest, and the bridge refuses an APK whose
  package or signing certificate differs from the installed app's. So a release APK must be signed with
  the release key, and a repository rename means changing `_kGitHubRepo`. The `FileProvider` exposes
  only `cache/updates/` (`file_paths.xml`), the folder the download goes to.
  To try an update end to end without publishing to users, build with
  `--dart-define=FORK_UPDATE_REPO=<owner>/<public repo>` and publish the test releases there.
- **google-services:** with `app/google-services.json` present the plugin runs for every variant and
  fails the build if the file does not list that variant's application ID.
- **Launcher aliases** (`${appIconAliasPrefix}.default` and the disabled alternates) are component
  names, not the application ID; keep them. The alternates are Fluxer art, so the picker is hidden
  (`_forkHasAlternateAppIcons`, `lib/core/platform/alternate_app_icon_settings.dart`).
- **A resource only Dart names** (by string) goes in `app/src/main/res/raw/keep.xml`, or resource
  shrinking drops it from release builds only.
- **Firebase metadata and Play Billing queries** belong in `app/src/fcm/AndroidManifest.xml`:
  `tool/configure_build.dart --profile=oss` refuses them in `main`.
- **The `<data>` elements of one intent filter combine:** a path on one line restricts every host. As
  written, the `settings` line's `pathPrefix="/user"` applies to the whole custom-scheme filter
  (upstream's; not checked on a device). Give a path its own filter.

## Links, sign-in and passkeys

- **The link scheme** is set three times: `deepLinkScheme` (Gradle), `forkAppLinkScheme` in
  `lib/core/deep_links/deep_link_path_policy.dart` (which reads `tyne` and `fluxer`), and `LINK_SCHEME`
  in `tool/fork_ios_identity.py`. Links inside messages stay `fluxer:`.
- **The SSO callback stays `fluxer://auth/sso/callback`**, as the instance decides: the filter on
  `SsoCallbackActivity`, `SsoAuthSessionTasks`, `SsoAuthService.callbackUrlScheme`, `LoginViewModel`.
- **https links:** the `autoVerify` filters name Fluxer's hosts, for which upstream's server lists only
  Fluxer's apps, and none names a Tyne instance. From Android 12, unverified links open in the browser.
- **Passkeys** need nothing here. Credential Manager (the `passkeys` plugin) offers an instance's
  passkeys only when its `/.well-known/assetlinks.json` names the app and its certificate. tyne-chat/tyne
  appends that statement to upstream's (`fluxer_app_proxy/src/routes/fork_android_association.rs`) and
  accepts the app's `android:apk-key-hash:` origin (`fluxer_api/src/api/auth/ForkPasskeyOrigins.ts`);
  change both together. Instances running upstream's server do not list Tyne.

## Network calls

The Kotlin code makes one request: the notification reply, one POST per reply, 20-second timeouts, no
retry, and a "Couldn't send reply" notification on failure (upstream's, in English). It bypasses Dio, so
no interceptors run and no `X-Tyne-Call-Site` header is sent. Measure (upstream's telemetry) starts only
if the user opted in and the build has a Measure key and URL.

## Known gaps

- Nothing in `lib/` or `android/` configures the embedded distributor; it merges two receivers into the
  app (tyne-chat/tyne#345). It does deliver Tyne's pushes: on 2026-11-02, logcat on Chiara's phone
  showed pushes arriving through `embedded_fcm_distributor.impl.FirebaseReceiver` (tyne-chat/tyne#474).

## Tests

- **Kotlin:** fourteen JUnit files in `app/src/test/kotlin/com/fluxer/`. Ten are upstream's; four are
  the fork's: `AppInstallBridgeTest.kt` (the installer's package, signer and path checks),
  `ForkPushEngineTest.kt` (the plugins the push engine leaves out),
  `FluxerUnifiedPushServiceForkTest.kt` (when the service destroys the push engine, with a stand-in
  engine, since a real one needs Flutter's native library) and `NotificationReplyForkTest.kt` (a reply
  asks the server for the selected persona). Upstream's `NotificationReplyTest.kt` expects that field
  too, under a `// Fork:` comment. The nightly rebase gate runs the
  fork's, by name: the root guide's "Before committing" has the command. Run them from `android/`
  once `gradlew` and `local.properties` exist (`flutter build apk --config-only` writes both without
  building), leaving out `:app:compileFlutterBuildCanaryUnifiedpushDebug`: without `-x` the task
  builds the Flutter app for Android, Rust included, which JVM tests do not need and which fails where
  Rust has no Android targets. Two of upstream's tests in `SsoAuthSessionTasksTest` fail there with `Method parse in
  android.net.Uri not mocked`: they call `Uri.parse` without Robolectric, which is why the gate
  names the fork's. A fork test goes in its own file, `Fork*Test.kt`, or `<UpstreamName>ForkTest.kt`
  for fork behaviour in an upstream class; a name outside those patterns is not run by the gate.
- **Dart ends** (in the root guide's test list): `test/core/deep_links/fork_app_link_scheme_test.dart`,
  `test/core/updater/`, `test/core/push/`, and upstream's `android_keyboard_insets_test.dart` and
  `mobile_keyboard_metrics_provider_test.dart` under `test/features/chat/`. After a manifest change also
  run `test/build/oss_configure_build_test.dart`, which is not in that list.
- **Off a device:** build the `canaryUnifiedpush` release APK and check its merged manifest, package
  name, version code and signer.
- **Only a device shows** the inset fix, links opening the app, passkeys, updates, notification replies
  and launcher icons: describe such changes as untested on device until a maintainer has tried them.
