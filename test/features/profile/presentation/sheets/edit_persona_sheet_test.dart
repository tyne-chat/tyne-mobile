// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/domain/public_persona.dart';
import 'package:fluxer_app/features/profile/presentation/sheets/edit_persona_sheet.dart';
import 'package:fluxer_app/features/profile/presentation/sheets/persona_copy_bar.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart';
import 'package:fluxer_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:fluxer_app/features/ui/button/fluxer_button.dart';
import 'package:fluxer_app/features/ui/input/fluxer_input.dart';
import 'package:fluxer_app/features/ui/settings/fluxer_save_bar.dart';
import 'package:fluxer_app/features/ui/toast/toast_provider.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/l10n_fork/fork_localizations_x.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_app/shared/utils/image_utils.dart';

import '../../../../helpers/pump_fluxer_app.dart';

class _FakeUserSettings extends UserSettingsViewModel {
  @override
  UserSettingsViewState build() => const UserSettingsViewState(
    userId: '1',
    username: 'tester',
    displayName: 'Tester',
    discriminator: '0001',
    avatar: null,
    avatarColor: null,
    memberSince: null,
    status: 'online',
    messageDisplayCompact: false,
    developerMode: false,
    trustedDomains: <String>[],
  );
}

class _FakeMyPersonasNotifier extends MyPersonasNotifier {
  _FakeMyPersonasNotifier([this._initial = const []]);

  final List<Persona> _initial;

  @override
  AsyncValue<List<Persona>> build() => AsyncData(_initial);

  @override
  Future<void> reloadSilently() async {}
}

/// Answers the persona image uploads and the persona save, and records each
/// request as `METHOD path` and the body of the last save.
class _PersonaApiAdapter implements HttpClientAdapter {
  final List<String> requests = <String>[];
  Map<String, dynamic>? lastSavedBody;
  int failBannerUploads = 0;
  int failCreates = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.startsWith('/users/@me/personas')) {
      requests.add('${options.method} ${options.path}');
      if (options.data case final Map<String, dynamic> body) {
        lastSavedBody = body;
      }
    }
    final ({int status, Object body}) reply = switch (options.path) {
      '/users/@me/personas/avatar' => (
        status: 200,
        body: <String, Object>{'avatar_hash': 'avatarhash', 'avatar_color': 5},
      ),
      '/users/@me/personas/banner' when failBannerUploads > 0 => (
        status: 500,
        body: <String, Object>{'message': 'Storage unavailable'},
      ),
      '/users/@me/personas/banner' => (
        status: 200,
        body: <String, Object>{'banner_hash': 'bannerhash'},
      ),
      '/users/@me/personas' when options.method == 'POST' && failCreates > 0 =>
        (status: 500, body: <String, Object>{'message': 'Server busy'}),
      _ => (
        status: 200,
        body: <String, Object>{'id': 'existing_p1', 'name': 'Existing Alter'},
      ),
    };
    if (options.path == '/users/@me/personas/banner' && failBannerUploads > 0) {
      failBannerUploads--;
    }
    if (options.path == '/users/@me/personas' &&
        options.method == 'POST' &&
        failCreates > 0) {
      failCreates--;
    }
    return ResponseBody.fromString(
      jsonEncode(reply.body),
      reply.status,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// A two-frame GIF: an animated image skips the cropper, so a test can pick
/// it without a crop sheet.
final Uint8List _animatedGif = Uint8List.fromList(<int>[
  ...ascii.encode('GIF89a'),
  0x01, 0x00, 0x01, 0x00, 0x80, 0x00, 0x00, //
  0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, //
  for (int frame = 0; frame < 2; frame++) ...<int>[
    0x21, 0xF9, 0x04, 0x00, 0x0A, 0x00, 0x00, 0x00, //
    0x2C, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, //
    0x02, 0x02, 0x44, 0x01, 0x00, //
  ],
  0x3B,
]);

class _FakeSystemDisplayTagNotifier extends SystemDisplayTagNotifier {
  @override
  SystemDisplayTag build() => const SystemDisplayTag(text: 'SYS');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const existingPersona = Persona(
    id: 'existing_p1',
    name: 'Existing Alter',
    personaTags: [PersonaTag(prefix: '[', suffix: ']')],
  );

  Widget buildTestBed({
    PublicPersona? persona,
    PublicPersona? copyOf,
    List<Persona> otherPersonas = const [],
    void Function(WidgetRef ref)? onRef,
    Dio? dio,
  }) {
    return pumpFluxerApp(
      overrides: [
        if (dio != null) fluxerDioProvider.overrideWithValue(dio),
        userSettingsViewModelProvider.overrideWith(_FakeUserSettings.new),
        myPersonasProvider.overrideWith(
          () => _FakeMyPersonasNotifier(otherPersonas),
        ),
        systemDisplayTagProvider.overrideWith(
          _FakeSystemDisplayTagNotifier.new,
        ),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          onRef?.call(ref);
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                key: const ValueKey('open_btn'),
                onPressed: () => EditPersonaSheet.show(
                  context,
                  persona: persona,
                  copyOf: copyOf,
                ),
                child: const Text('Open'),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> openSheet(
    WidgetTester tester, {
    PublicPersona? persona,
    PublicPersona? copyOf,
    List<Persona> otherPersonas = const [],
    void Function(WidgetRef ref)? onRef,
    Dio? dio,
  }) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      buildTestBed(
        persona: persona,
        copyOf: copyOf,
        otherPersonas: otherPersonas,
        onRef: onRef,
        dio: dio,
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open_btn')));
    await tester.pumpAndSettle();
  }

  /// Scrolls the sheet's form until [target] is built and on screen: the
  /// buttons at its end are below what the list builds at first.
  Future<void> scrollTo(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      300,
      scrollable: find
          .descendant(
            of: find.byType(ListView).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
  }

  bool isSaveBarVisible(WidgetTester tester) {
    final saveBar = tester.widget<FluxerSaveBar>(find.byType(FluxerSaveBar));
    return saveBar.visible;
  }

  group('EditPersonaSheet - Creation Mode', () {
    testWidgets('renders create persona form with default fields', (
      tester,
    ) async {
      await openSheet(tester);

      expect(find.text('Create Persona'), findsOneWidget);
      expect(find.byType(FluxerInput), findsWidgets);
      expect(find.text('Persona Tags'), findsOneWidget);
      expect(find.text('Add Tag Pair (1/5)'), findsOneWidget);
      expect(isSaveBarVisible(tester), isFalse);
    });

    testWidgets(
      'typing in name field triggers dirty state and displays SaveBar',
      (tester) async {
        await openSheet(tester);

        // Name field is index 1
        final nameInput = find.byType(TextField).at(1);
        await tester.enterText(nameInput, 'New Persona Name');
        await tester.pumpAndSettle();

        expect(isSaveBarVisible(tester), isTrue);

        // Tapping Reset reverts changes and hides SaveBar
        await tester.tap(find.text('Reset'));
        await tester.pumpAndSettle();

        expect(isSaveBarVisible(tester), isFalse);
      },
    );

    testWidgets('adding and removing tag pairs updates list', (tester) async {
      await openSheet(tester);

      final addTagBtn = find.text('Add Tag Pair (1/5)');
      expect(addTagBtn, findsOneWidget);
      await tester.tap(addTagBtn);
      await tester.pumpAndSettle();

      expect(find.text('Add Tag Pair (2/5)'), findsOneWidget);
    });

    // Prefix 'a:::' with suffix 'b' and prefix 'a' with suffix ':::b' are
    // different tags; the check once joined them with ':::' and saw the same
    // key.
    testWidgets(
      'does not take tags containing the old separator for duplicates',
      (tester) async {
        final adapter = _PersonaApiAdapter();
        final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
          ..httpClientAdapter = adapter;
        await openSheet(tester, dio: dio);

        // Field 0 is the colour, 1 the name.
        await tester.enterText(find.byType(TextField).at(1), 'Colons');
        await tester.enterText(find.byType(TextField).at(3), 'a:::');
        await tester.enterText(find.byType(TextField).at(4), 'b');
        await tester.tap(find.text('Add Tag Pair (1/5)'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).at(5), 'a');
        await tester.enterText(find.byType(TextField).at(6), ':::b');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(adapter.requests, <String>['POST /users/@me/personas']);
      },
    );

    testWidgets('validates required name on save', (tester) async {
      WidgetRef? capturedRef;
      await openSheet(tester, onRef: (ref) => capturedRef = ref);

      // Add a non-empty tag prefix (index 3) to make form dirty while name is empty
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(3), 'tag:');
      await tester.pumpAndSettle();

      expect(isSaveBarVisible(tester), isTrue);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final toasts = capturedRef!.read(toastProvider);
      expect(toasts, isNotEmpty);
      expect(
        toasts.any((t) => t.toast.message.contains('persona display name')),
        isTrue,
      );
    });

    testWidgets('validates tag collision against existing personas', (
      tester,
    ) async {
      WidgetRef? capturedRef;
      await openSheet(
        tester,
        otherPersonas: const [existingPersona],
        onRef: (ref) => capturedRef = ref,
      );

      final textFields = find.byType(TextField);
      // Name is index 1
      await tester.enterText(textFields.at(1), 'Colliding Alter');
      // Tag 1 Prefix is index 3, Suffix is index 4
      await tester.enterText(textFields.at(3), '[');
      await tester.enterText(textFields.at(4), ']');
      await tester.pumpAndSettle();

      expect(isSaveBarVisible(tester), isTrue);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final toasts = capturedRef!.read(toastProvider);
      expect(toasts, isNotEmpty);
      expect(
        toasts.any(
          (t) =>
              t.toast.message.contains('already used by') ||
              t.toast.message.contains('Existing Alter'),
        ),
        isTrue,
      );
    });

    testWidgets('validates duplicate tag pairs on the same persona', (
      tester,
    ) async {
      WidgetRef? capturedRef;
      await openSheet(tester, onRef: (ref) => capturedRef = ref);

      final textFields = find.byType(TextField);
      // Name is index 1
      await tester.enterText(textFields.at(1), 'Valid Name');
      // Tag 1 Prefix is index 3
      await tester.enterText(textFields.at(3), '{');

      // Add second tag pair
      await tester.tap(find.text('Add Tag Pair (1/5)'));
      await tester.pumpAndSettle();

      final updatedFields = find.byType(TextField);
      // Second tag pair prefix is now index 5
      await tester.enterText(updatedFields.at(5), '{');
      await tester.pumpAndSettle();

      expect(isSaveBarVisible(tester), isTrue);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final toasts = capturedRef!.read(toastProvider);
      expect(toasts, isNotEmpty);
      expect(
        toasts.any((t) => t.toast.message.contains('Duplicate tag pair')),
        isTrue,
      );
    });
  });

  group('EditPersonaSheet - Edit Mode', () {
    const publicPersona = PublicPersona(
      id: 'p_test',
      name: 'Test Persona',
      pronouns: 'they/them',
      bio: 'Testing persona edit sheet',
      personaTags: [PersonaTag(prefix: 't:', suffix: '')],
      color: 0x5865F2,
    );

    testWidgets('renders existing persona details and delete button', (
      tester,
    ) async {
      await openSheet(tester, persona: publicPersona);

      expect(find.text('Edit Persona'), findsOneWidget);

      final textFields = find.byType(TextField);
      // Color is at 0, Name is at 1, Pronouns is at 2, Tag prefix at 3, Suffix at 4, Bio at 5
      final nameField = tester.widget<TextField>(textFields.at(1));
      expect(nameField.controller?.text, 'Test Persona');

      final pronounsField = tester.widget<TextField>(textFields.at(2));
      expect(pronounsField.controller?.text, 'they/them');

      final bioField = tester.widget<TextField>(textFields.at(5));
      expect(bioField.controller?.text, 'Testing persona edit sheet');

      // Verify Delete Persona button exists
      final deleteButton = find.text('Delete Persona');
      await scrollTo(tester, deleteButton);
      expect(deleteButton, findsOneWidget);

      // Tap delete button to open confirmation dialog
      await tester.ensureVisible(deleteButton);
      await tester.pumpAndSettle();
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Are you sure you want to delete "Test Persona"? You can restore '
          'deleted personas later in Settings › Personas, under Deleted '
          'personas.',
        ),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);

      // Cancel dismissal
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Cancel'), findsNothing);
    });

    testWidgets(
      'renders existing signature emojis, allows removing a chip, and resets on demand',
      (tester) async {
        const personaWithSigs = PublicPersona(
          id: 'p_sig_test',
          name: 'Signature Persona',
          pronouns: 'they/them',
          personaTags: [PersonaTag(prefix: 's:', suffix: '')],
          signatureEmojis: [
            SignatureEmoji(name: '🌟'),
            SignatureEmoji(
              id: 'custom_123',
              name: 'custom_star',
              animated: false,
            ),
          ],
        );

        await openSheet(tester, persona: personaWithSigs);

        // Verify button shows count and custom emoji label appears
        expect(find.text('Add Emoji (2)'), findsOneWidget);
        expect(find.text(':custom_star:'), findsOneWidget);
        expect(isSaveBarVisible(tester), isFalse);

        // Remove the first signature emoji chip
        final removeButtons = find.bySemanticsLabel('Remove signature emoji');
        expect(removeButtons, findsNWidgets(2));
        await tester.tap(removeButtons.first);
        await tester.pumpAndSettle();

        // Count decrements and SaveBar is now visible
        expect(find.text('Add Emoji (1)'), findsOneWidget);
        expect(isSaveBarVisible(tester), isTrue);

        // Reset restores original state and hides SaveBar
        await tester.tap(find.text('Reset'));
        await tester.pumpAndSettle();

        expect(find.text('Add Emoji (2)'), findsOneWidget);
        expect(isSaveBarVisible(tester), isFalse);
      },
    );

    testWidgets(
      'validates signature emoji collision against existing personas on save without literal backslashes',
      (tester) async {
        WidgetRef? capturedRef;
        const personaWithCollision = PublicPersona(
          id: 'p_colliding',
          name: 'Alice',
          personaTags: [PersonaTag(prefix: 'a:', suffix: '')],
          signatureEmojis: [SignatureEmoji(name: '🦊')],
        );
        const otherPersona = Persona(
          id: 'p_other',
          name: 'Bob the Fox',
          signatureEmojis: [SignatureEmoji(name: '🦊')],
        );

        await openSheet(
          tester,
          persona: personaWithCollision,
          otherPersonas: const [otherPersona],
          onRef: (ref) => capturedRef = ref,
        );

        // Make a change to trigger the save bar
        final textFields = find.byType(TextField);
        await tester.enterText(textFields.at(2), 'she/her');
        await tester.pumpAndSettle();

        expect(isSaveBarVisible(tester), isTrue);
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        final toasts = capturedRef!.read(toastProvider);
        expect(toasts, isNotEmpty);
        final toastMessage = toasts.last.toast.message;
        expect(toastMessage, contains('Bob the Fox'));
        expect(toastMessage, contains('"Bob the Fox"'));
        expect(toastMessage, isNot(contains(r'\"')));
        expect(
          toastMessage,
          'Signature emoji already in use by persona "Bob the Fox"',
        );
      },
    );

    test(
      'personaSignatureEmojiAlreadyUsedByOther formats cleanly across all supported locales',
      () async {
        for (final locale in FluxerLocalizations.supportedLocales) {
          final l10n = await FluxerLocalizations.delegate.load(locale);
          final formatted = l10n.fork.personaSignatureEmojiAlreadyUsedByOther(
            'Bob the Fox',
          );
          expect(
            formatted,
            contains('Bob the Fox'),
            reason: 'Locale ${locale.languageCode} should contain persona name',
          );
          expect(
            formatted,
            isNot(contains(r'\"')),
            reason:
                'Locale ${locale.languageCode} must not contain literal backslashes',
          );
        }
      },
    );
  });

  // Like upstream's profile editor, a picked image is only uploaded on Save
  // (tyne-chat/tyne#204).
  group('EditPersonaSheet - not matching tags', () {
    const label = "Don't match this persona's tags";

    Future<_PersonaApiAdapter> openWithApi(
      WidgetTester tester,
      PublicPersona persona,
    ) async {
      final adapter = _PersonaApiAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = adapter;
      await openSheet(tester, persona: persona, dio: dio);
      return adapter;
    }

    Future<void> toggle(WidgetTester tester) async {
      await tester.ensureVisible(find.text(label));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    testWidgets('turning it on saves the flag', (tester) async {
      final adapter = await openWithApi(
        tester,
        const PublicPersona(id: 'existing_p1', name: 'Existing Alter'),
      );
      expect(isSaveBarVisible(tester), isFalse);

      await toggle(tester);
      expect(isSaveBarVisible(tester), isTrue);

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(adapter.lastSavedBody?['auto_tag_disabled'], isTrue);
    });

    testWidgets('a persona with it on can turn it off', (tester) async {
      final adapter = await openWithApi(
        tester,
        const PublicPersona(
          id: 'existing_p1',
          name: 'Existing Alter',
          autoTagDisabled: true,
        ),
      );

      await toggle(tester);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(adapter.lastSavedBody?['auto_tag_disabled'], isFalse);
    });

    testWidgets('Reset takes it back', (tester) async {
      await openWithApi(
        tester,
        const PublicPersona(id: 'existing_p1', name: 'Existing Alter'),
      );

      await toggle(tester);
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      expect(isSaveBarVisible(tester), isFalse);
    });
  });

  group('EditPersonaSheet - picked images', () {
    const persona = PublicPersona(id: 'existing_p1', name: 'Existing Alter');

    Future<_PersonaApiAdapter> openWithApi(
      WidgetTester tester, {
      void Function(WidgetRef ref)? onRef,
    }) async {
      final adapter = _PersonaApiAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = adapter;
      EditPersonaSheet.pickImage = () async =>
          (bytes: _animatedGif, name: 'picked.gif');
      addTearDown(() => EditPersonaSheet.pickImage = ImageUtils.pickImage);
      await openSheet(tester, persona: persona, dio: dio, onRef: onRef);
      return adapter;
    }

    Future<void> tapText(WidgetTester tester, String text) async {
      await tester.ensureVisible(find.text(text).last);
      await tester.tap(find.text(text).last);
      await tester.pumpAndSettle();
    }

    testWidgets('picking an avatar sends nothing until Save', (tester) async {
      final adapter = await openWithApi(tester);

      await tapText(tester, 'Upload Avatar');

      expect(adapter.requests, isEmpty);
      expect(isSaveBarVisible(tester), isTrue);

      await tapText(tester, 'Save');

      expect(adapter.requests, <String>[
        'POST /users/@me/personas/avatar',
        'PATCH /users/@me/personas/existing_p1',
      ]);
    });

    testWidgets('Reset drops a picked image without uploading it', (
      tester,
    ) async {
      final adapter = await openWithApi(tester);

      await tapText(tester, 'Change banner');
      expect(isSaveBarVisible(tester), isTrue);
      await tapText(tester, 'Reset');

      expect(isSaveBarVisible(tester), isFalse);
      expect(adapter.requests, isEmpty);
    });

    testWidgets(
      'a failed upload saves nothing, and Save again does not upload a stored image twice',
      (tester) async {
        WidgetRef? capturedRef;
        final adapter = await openWithApi(
          tester,
          onRef: (ref) => capturedRef = ref,
        );
        adapter.failBannerUploads = 1;

        await tapText(tester, 'Upload Avatar');
        await tapText(tester, 'Change banner');
        await tapText(tester, 'Save');

        expect(adapter.requests, <String>[
          'POST /users/@me/personas/avatar',
          'POST /users/@me/personas/banner',
        ]);
        expect(
          capturedRef!.read(toastProvider).last.toast.message,
          contains('Storage unavailable'),
        );
        expect(isSaveBarVisible(tester), isTrue);

        await tapText(tester, 'Save');

        expect(adapter.requests, <String>[
          'POST /users/@me/personas/avatar',
          'POST /users/@me/personas/banner',
          'POST /users/@me/personas/banner',
          'PATCH /users/@me/personas/existing_p1',
        ]);
      },
    );
  });

  group('EditPersonaSheet - Duplicate (tyne-chat/tyne#599)', () {
    const lyra = PublicPersona(
      id: 'lyra_1',
      name: 'Lyra',
      pronouns: 'she/they',
      bio: 'Night owl, stargazer.',
      avatarHash: 'lyraavatar',
      avatarColor: 0x26225E,
      bannerHash: 'lyrabanner',
      color: 0x7B6CF6,
      visibility: 'public',
      autoTagDisabled: true,
      personaTags: [
        PersonaTag(prefix: 'Ly:'),
        PersonaTag(prefix: '[', suffix: ']'),
      ],
      signatureEmojis: [SignatureEmoji(name: '🌙')],
    );
    const List<Persona> personas = [
      Persona(id: 'lyra_1', name: 'Lyra'),
      Persona(id: 'lyra_2', name: 'Lyra (2)'),
    ];

    Future<_PersonaApiAdapter> openWithApi(
      WidgetTester tester, {
      PublicPersona? persona,
      PublicPersona? copyOf,
    }) async {
      final adapter = _PersonaApiAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = adapter;
      await openSheet(
        tester,
        persona: persona,
        copyOf: copyOf,
        otherPersonas: personas,
        dio: dio,
      );
      return adapter;
    }

    Future<void> tapText(WidgetTester tester, String text) async {
      await tester.ensureVisible(find.text(text).last);
      await tester.tap(find.text(text).last);
      await tester.pumpAndSettle();
    }

    TextField nameField(WidgetTester tester) =>
        tester.widget<TextField>(find.byType(TextField).at(1));

    FluxerButton duplicateButton(WidgetTester tester) =>
        tester.widget<FluxerButton>(
          find.widgetWithText(FluxerButton, 'Duplicate Persona'),
        );

    testWidgets(
      "Duplicate closes the persona's editor and opens a copy under the next free number",
      (tester) async {
        final adapter = await openWithApi(tester, persona: lyra);
        expect(find.text('New Persona'), findsNothing);
        await scrollTo(tester, find.text('Duplicate Persona'));

        await tapText(tester, 'Duplicate Persona');

        expect(find.text('Edit Persona'), findsNothing);
        expect(find.text('Create Persona'), findsOneWidget);
        expect(find.text('Copy of Lyra'), findsOneWidget);
        // The badge on the preview's banner tells the copy from the original.
        expect(find.text('New Persona'), findsOneWidget);
        expect(find.byType(FluxerSaveBar), findsNothing);
        final TextField name = nameField(tester);
        expect(name.controller?.text, 'Lyra (3)');
        expect(
          name.controller?.selection,
          const TextSelection(baseOffset: 0, extentOffset: 8),
        );
        expect(
          tester
              .widget<TextField>(find.byType(TextField).at(2))
              .controller
              ?.text,
          'she/they',
        );
        // One empty tag pair, and no signature emoji chips.
        expect(find.text('Add Tag Pair (1/5)'), findsOneWidget);
        expect(
          tester
              .widget<TextField>(find.byType(TextField).at(3))
              .controller
              ?.text,
          isEmpty,
        );
        expect(find.text('🌙'), findsNothing);
        expect(adapter.requests, isEmpty);
      },
    );

    testWidgets(
      'Create sends one request, with the same pictures and no tags or emojis',
      (tester) async {
        final adapter = await openWithApi(tester, copyOf: lyra);

        await tapText(tester, 'Create');

        expect(adapter.requests, <String>['POST /users/@me/personas']);
        expect(adapter.lastSavedBody, <String, dynamic>{
          'name': 'Lyra (3)',
          'avatar_hash': 'lyraavatar',
          'banner_hash': 'lyrabanner',
          'color': 0x7B6CF6,
          'avatar_color': 0x26225E,
          'pronouns': 'she/they',
          'bio': 'Night owl, stargazer.',
          'auto_tag_disabled': true,
          'persona_tags': <Map<String, dynamic>>[],
          'signature_emojis': <Map<String, dynamic>>[],
          'visibility': 'public',
        });
        expect(find.text('Copy of Lyra'), findsNothing);
      },
    );

    testWidgets(
      'a failed Create keeps the copy open as it was, and Create again sends it once more',
      (tester) async {
        final adapter = await openWithApi(tester, copyOf: lyra);
        adapter.failCreates = 1;

        await tapText(tester, 'Create');

        expect(adapter.requests, <String>['POST /users/@me/personas']);
        expect(find.text('Copy of Lyra'), findsOneWidget);
        expect(nameField(tester).controller?.text, 'Lyra (3)');

        await tapText(tester, 'Create');

        expect(adapter.requests, <String>[
          'POST /users/@me/personas',
          'POST /users/@me/personas',
        ]);
        expect(find.text('Copy of Lyra'), findsNothing);
      },
    );

    testWidgets('the bar sits below the form, not over it', (tester) async {
      await openWithApi(tester, copyOf: lyra);

      final Rect bar = tester.getRect(find.byType(PersonaCopyBar));
      final Rect list = tester.getRect(find.byType(ListView).first);
      expect(list.bottom, lessThanOrEqualTo(bar.top));
    });

    testWidgets('Cancel closes the copy without a request; Back does not', (
      tester,
    ) async {
      final adapter = await openWithApi(tester, copyOf: lyra);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Copy of Lyra'), findsOneWidget);

      await tapText(tester, 'Cancel');

      expect(find.text('Copy of Lyra'), findsNothing);
      expect(adapter.requests, isEmpty);
    });

    testWidgets('Duplicate is off while the persona has unsaved changes', (
      tester,
    ) async {
      await openWithApi(tester, persona: lyra);
      await scrollTo(tester, find.text('Duplicate Persona'));
      expect(duplicateButton(tester).onPressed, isNotNull);

      await tester.enterText(find.byType(TextField).at(2), 'she/her');
      await tester.pumpAndSettle();
      expect(duplicateButton(tester).onPressed, isNull);

      await tapText(tester, 'Reset');
      expect(duplicateButton(tester).onPressed, isNotNull);
    });
  });
}
