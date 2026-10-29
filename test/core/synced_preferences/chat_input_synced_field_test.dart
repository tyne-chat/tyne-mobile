import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/synced_preferences/engine/fork_synced_field_registry.dart';
import 'package:fluxer_app/core/synced_preferences/engine/synced_preference_field.dart';
import 'package:fluxer_app/core/synced_preferences/engine/synced_preferences_store.dart';
import 'package:fluxer_app/core/synced_preferences/generated/fluxer/user/preferences/v1/preferences.pb.dart'
    as pb;
import 'package:fluxer_app/features/chat/utils/composer/emoticon_conversion.dart';
import 'package:fluxer_app/features/settings/providers/preferences/convert_emoticons_preference.dart';

import '../../helpers/open_test_database.dart';
import '../../helpers/synced_preferences_test_helpers.dart';

// Fork: `chat_input.convert_emoticons`, the web's "Turn text smileys into
// emoji", through the store (tyne-chat/tyne#260).
void main() {
  late RecordingUsersApi api;
  late ProviderContainer container;
  late SyncedPreferencesStore store;

  bool convertEmoticons() => container.read(convertEmoticonsPreferenceProvider);

  setUp(() {
    // A loaded table keeps the preference from loading the emoji asset.
    setEmoticonTableForTesting(const <String, String>{});
    api = RecordingUsersApi();
    container = ProviderContainer(
      overrides: [
        fluxerDatabaseProvider.overrideWithValue(openTestDatabase()),
        fluxerClientProvider.overrideWithValue(RecordingFluxerClient(api)),
        currentUserIdProvider.overrideWithValue('user-1'),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(() => setEmoticonTableForTesting(null));
    store = container.read(syncedPreferencesStoreProvider);
  });

  test('the fork registers the chat_input field', () {
    final List<SyncedPreferenceField> fields = container.read(
      Provider<List<SyncedPreferenceField>>((Ref ref) {
        final List<SyncedPreferenceField> fields = <SyncedPreferenceField>[];
        registerForkSyncedFieldAdapters(
          registerAdapter: (adapter) => fields.add(adapter.field),
          ref: ref,
        );
        return fields;
      }),
    );
    expect(fields, contains(SyncedPreferenceField.chatInput));
  });

  test('takes the web setting from chat_input', () async {
    await store.hydrateFromUserSettings(
      syncedPreferencesUserSettings(
        pb.SyncedPreferences(
          chatInput: pb.ChatInputSettings(convertEmoticons: true),
        ),
      ),
    );
    expect(convertEmoticons(), isTrue);
    expect(api.pushes, isEmpty);
  });

  test('a blob without chat_input means off', () async {
    await container
        .read(convertEmoticonsPreferenceProvider.notifier)
        .applySynced(value: true);
    await store.hydrateFromUserSettings(
      syncedPreferencesUserSettings(
        pb.SyncedPreferences(
          sidebar: pb.SidebarPreferences(inlineDmsCollapsed: true),
        ),
      ),
    );
    expect(convertEmoticons(), isFalse);
    expect(api.pushes, isEmpty);
  });

  test('turning it on pushes once and keeps the rest of chat_input', () async {
    await store.hydrateFromUserSettings(
      syncedPreferencesUserSettings(
        pb.SyncedPreferences(
          chatInput: pb.ChatInputSettings(saveCameraCapturesToDevice: false),
          sidebar: pb.SidebarPreferences(inlineDmsCollapsed: true),
        ),
      ),
    );
    await container
        .read(convertEmoticonsPreferenceProvider.notifier)
        .setConvertEmoticons(value: true);
    await flushSyncedPreferencesDebounce(store);

    expect(api.pushes, hasLength(1));
    final pb.SyncedPreferences pushed = api.lastPush;
    expect(pushed.chatInput.convertEmoticons, isTrue);
    expect(pushed.chatInput.hasSaveCameraCapturesToDevice(), isTrue);
    expect(pushed.chatInput.saveCameraCapturesToDevice, isFalse);
    expect(pushed.sidebar.inlineDmsCollapsed, isTrue);
  });

  test('turning it off leaves the field out, as the web does', () async {
    await store.hydrateFromUserSettings(
      syncedPreferencesUserSettings(
        pb.SyncedPreferences(
          chatInput: pb.ChatInputSettings(convertEmoticons: true),
        ),
      ),
    );
    await container
        .read(convertEmoticonsPreferenceProvider.notifier)
        .setConvertEmoticons(value: false);
    await flushSyncedPreferencesDebounce(store);

    expect(api.pushes, hasLength(1));
    expect(api.lastPush.chatInput.hasConvertEmoticons(), isFalse);
  });

  group('convertOutgoingEmoticons', () {
    String convert(String text) {
      final Provider<String> probe = Provider<String>(
        (Ref ref) => convertOutgoingEmoticons(ref, text),
      );
      return container.read(probe);
    }

    test('converts only while the setting is on', () async {
      setEmoticonTableForTesting(const <String, String>{':)': '\u{1F642}'});
      expect(convert('hi :)'), 'hi :)');
      await container
          .read(convertEmoticonsPreferenceProvider.notifier)
          .applySynced(value: true);
      expect(convert('hi :)'), 'hi \u{1F642}');
    });
  });
}
