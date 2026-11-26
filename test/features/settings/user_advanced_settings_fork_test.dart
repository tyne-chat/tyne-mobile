// Fork: tests for the "Add a space after emoji" switch in Advanced > Chat and
// its settings search entry (tyne-chat/tyne#650), kept out of upstream's
// user_advanced_settings_test.dart and user_settings_search_test.dart.
// Root ProviderScope built by a helper; the lint only exempts a
// ProviderScope written inline in pumpWidget.
// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/observability/observability_reporting_provider.dart';
import 'package:fluxer_app/core/synced_preferences/engine/synced_preference_field.dart';
import 'package:fluxer_app/core/synced_preferences/engine/synced_preferences_store.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/features/settings/domain/user_settings_section.dart';
import 'package:fluxer_app/features/settings/presentation/widgets/user_advanced_settings.dart';
import 'package:fluxer_app/features/settings/providers/preferences/advanced_preferences_provider.dart';
import 'package:fluxer_app/features/settings/providers/preferences/appearance_preferences_provider.dart';
import 'package:fluxer_app/features/settings/providers/preferences/chat_preferences_provider.dart';
import 'package:fluxer_app/features/settings/providers/preferences/local_settings_provider.dart';
import 'package:fluxer_app/features/settings/providers/preferences/space_after_emoji_preference.dart';
import 'package:fluxer_app/features/settings/providers/preferences/voice_settings_provider.dart';
import 'package:fluxer_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:fluxer_app/features/settings/utils/user_settings/user_settings_search.dart';
import 'package:fluxer_app/features/voice/domain/voice_settings_state.dart';
import 'package:fluxer_app/l10n_fork/fork_localizations_x.dart';
import 'package:fluxer_app/material_ui.dart';

import '../../helpers/test_l10n.dart';

class _RecordingSyncedPreferencesStore extends SyncedPreferencesStore {
  // Test stub cannot match SyncedPreferencesStore's private `_ref` parameter.
  // ignore: use_super_parameters
  _RecordingSyncedPreferencesStore(Ref ref) : super(ref);

  final List<SyncedPreferenceField> dirtyFields = <SyncedPreferenceField>[];

  @override
  void markDirty(SyncedPreferenceField field) {
    dirtyFields.add(field);
  }

  @override
  void scheduleFlush() {}
}

class _FakeAdvancedPreferences extends AdvancedPreferences {
  @override
  AdvancedPreferencesState build() => const AdvancedPreferencesState();
}

class _FakeAppearancePreferences extends AppearancePreferences {
  @override
  AppearancePreferencesState build() => const AppearancePreferencesState();
}

class _FakeChatPreferences extends ChatPreferences {
  @override
  ChatPreferencesState build() => const ChatPreferencesState();
}

class _FakeUserSettings extends UserSettingsViewModel {
  @override
  UserSettingsViewState build() => const UserSettingsViewState(
    userId: 'u1',
    username: 'tester',
    displayName: 'Tester',
    discriminator: '0',
    avatar: null,
    avatarColor: null,
    memberSince: null,
    status: 'online',
    messageDisplayCompact: false,
    developerMode: false,
    trustedDomains: <String>[],
  );
}

class _FakeVoiceSettings extends VoiceSettings {
  @override
  VoiceSettingsState build() => const VoiceSettingsState();
}

class _FakeObservabilityReporting extends ObservabilityReporting {
  @override
  bool build() => false;
}

class _FakeLocalSettings extends LocalSettings {
  @override
  LocalSettingsState build() => const LocalSettingsState();
}

void main() {
  final FluxerLocalizations l10n = testL10n;

  testWidgets(
    'Add a space after emoji switch renders in Advanced > Chat and toggles synced preference',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      late _RecordingSyncedPreferencesStore store;
      final colorTheme = buildDarkColorTheme();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            syncedPreferencesStoreProvider.overrideWith(
              (Ref ref) => store = _RecordingSyncedPreferencesStore(ref),
            ),
            advancedPreferencesProvider.overrideWith(
              _FakeAdvancedPreferences.new,
            ),
            appearancePreferencesProvider.overrideWith(
              _FakeAppearancePreferences.new,
            ),
            chatPreferencesProvider.overrideWith(_FakeChatPreferences.new),
            userSettingsViewModelProvider.overrideWith(_FakeUserSettings.new),
            voiceSettingsProvider.overrideWith(_FakeVoiceSettings.new),
            observabilityReportingProvider.overrideWith(
              _FakeObservabilityReporting.new,
            ),
            localSettingsProvider.overrideWith(_FakeLocalSettings.new),
          ],
          child: MaterialApp(
            locale: kTestLocale,
            localizationsDelegates: fluxerLocalizationsDelegates,
            supportedLocales: FluxerLocalizations.supportedLocales,
            theme: buildFluxerTheme(
              colorTheme: colorTheme,
              textTheme: FluxerTextTheme.fromColors(colorTheme),
              layoutTheme: FluxerLayoutTheme.scaled(),
            ),
            home: const Scaffold(body: UserAdvancedSettings()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final Finder toggle = find.bySemanticsLabel(
        testSettingsSwitchSemanticsLabel(
          label: l10n.fork.advancedSettingSpaceAfterEmojiLabel,
          description: l10n.fork.advancedSettingSpaceAfterEmojiDescription,
        ),
      );
      await tester.scrollUntilVisible(
        toggle,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(toggle, findsOneWidget);

      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(UserAdvancedSettings)),
      );
      expect(container.read(spaceAfterEmojiPreferenceProvider), isTrue);

      await tester.tap(toggle);
      await tester.pumpAndSettle();

      expect(container.read(spaceAfterEmojiPreferenceProvider), isFalse);
      expect(store.dirtyFields, <SyncedPreferenceField>[
        SyncedPreferenceField.accessibility,
      ]);
    },
  );

  group('settings search for Add a space after emoji', () {
    test('finds the switch by label and keyword in Advanced > Chat', () {
      for (final String query in <String>[
        'Add a space after emoji',
        'emoji spacing',
        'pictures made of several emoji',
      ]) {
        final List<UserSettingsSearchHit> hits = searchUserSettings(
          l10n: l10n,
          query: query,
          visibleSections: const <UserSettingsSection>{
            UserSettingsSection.advanced,
          },
          isTouchPrimary: true,
        );
        expect(
          hits.any(
            (UserSettingsSearchHit hit) =>
                hit.section == UserSettingsSection.advanced &&
                hit.fieldId == 'advanced-settings-chat' &&
                hit.label == l10n.fork.advancedSettingSpaceAfterEmojiLabel,
          ),
          isTrue,
          reason: 'query: $query',
        );
      }
    });
  });
}
