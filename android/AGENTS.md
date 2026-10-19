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

**Reply from a notification:** Dart posts the notification, then `attachAndroidNotificationReply` has
Kotlin add a reply action to it. On reply, `FluxerNotificationReplyReceiver` reads the account's token
and API base from secure storage and `HttpNotificationReplyPoster` posts to `/channels/{id}/messages`
under a 30-second wake lock, without starting Flutter.

## The fork's changes and where they sit

| Change | Where and how |
|---|---|
| ID, label, link scheme | `canary` flavour and `defaultConfig` in `app/build.gradle.kts`, under `// Fork:` comments; `${deepLinkScheme}` in the seven `<data>` lines of the manifest's custom-scheme filter |
| Artwork | fork-owned, generated files in `app/src/canary/res/` that replace `main`'s by resource name (`drawable/fluxer_logo_monochrome.xml` points at `tyne_notification_glyph`); do not edit them by hand. One upstream line changed: the colour in `values/ic_launcher_background.xml` |
| APK installer | fork-owned `AppInstallBridge.kt` and `file_paths.xml`; a `REQUEST_INSTALL_PACKAGES` line; the `FileProvider` appended to `<application>` (no fork comment); registered first in `configureFlutterEngine` |
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

Tracked in tyne-chat/tyne#155.

- A notification reply carries no `persona_id` (here and in Dart's reply path): it goes out as the
  account even where a persona is selected.
- Nothing in `lib/` or `android/` configures the embedded distributor; it merges two receivers into the
  app. Whether it delivers anything for Tyne has not been checked.

## Tests

- **Kotlin:** nine JUnit files in `app/src/test/kotlin/com/fluxer/`: eight upstream's and the fork's
  `AppInstallBridgeTest.kt` (the installer's package, signer and path checks). No check or workflow
  runs them. Run them from `android/` once a Flutter build has
  written `gradlew` and `local.properties`, for example
  `./gradlew :app:testCanaryUnifiedpushDebugUnitTest`. A fork test goes in its own file
  (`<UpstreamName>ForkTest.kt` for fork behaviour in an upstream class).
- **Dart ends** (in the root guide's test list): `test/core/deep_links/fork_app_link_scheme_test.dart`,
  `test/core/updater/`, `test/core/push/`, and upstream's `android_keyboard_insets_test.dart` and
  `mobile_keyboard_metrics_provider_test.dart` under `test/features/chat/`. After a manifest change also
  run `test/build/oss_configure_build_test.dart`, which is not in that list.
- **Off a device:** build the `canaryUnifiedpush` release APK and check its merged manifest, package
  name, version code and signer.
- **Only a device shows** the inset fix, links opening the app, passkeys, updates, notification replies
  and launcher icons: describe such changes as untested on device until a maintainer has tried them.
