// Fork: the pinned emojis' synced field (tyne-chat/tyne#140), through the store
// as the app runs it: what arrives from the server's blob, and what is pushed.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/synced_preferences/engine/fork_synced_field_registry.dart';
import 'package:fluxer_app/core/synced_preferences/engine/synced_preference_field.dart';
import 'package:fluxer_app/core/synced_preferences/engine/synced_preferences_store.dart';
import 'package:fluxer_app/core/synced_preferences/generated/fluxer/user/preferences/v1/fork_emoji_pins.pb.dart'
    as pins_pb;
import 'package:fluxer_app/core/synced_preferences/generated/fluxer/user/preferences/v1/preferences.pb.dart'
    as pb;
import 'package:fluxer_app/features/emoji/data/emoji_pins_storage.dart';
import 'package:fluxer_app/features/emoji/domain/emoji_pins.dart';
import 'package:fluxer_app/features/emoji/providers/emoji_pins_provider.dart';

import '../../helpers/open_test_database.dart';
import '../../helpers/synced_preferences_test_helpers.dart';

const String _userId = 'user-1';

pb.SyncedPreferences _blob({
  List<String>? pinned,
  Map<String, List<String>> personas = const <String, List<String>>{},
}) => pb.SyncedPreferences(
  // A field of upstream's, which a push must send back as it came.
  sidebar: pb.SidebarPreferences(inlineDmsCollapsed: true),
  emojiPins: pinned == null
      ? null
      : pins_pb.EmojiPinsState(
          pinnedEmojiIds: pinned,
          personaPins: <String, pins_pb.PersonaEmojiPins>{
            for (final MapEntry<String, List<String>> entry in personas.entries)
              entry.key: pins_pb.PersonaEmojiPins(emojiIds: entry.value),
          }.entries,
        ),
);

void main() {
  late db.FluxerDatabase database;
  late RecordingUsersApi api;
  late ProviderContainer container;
  late SyncedPreferencesStore store;

  setUp(() {
    database = openTestDatabase();
    api = RecordingUsersApi();
    container = ProviderContainer(
      overrides: [
        fluxerDatabaseProvider.overrideWithValue(database),
        fluxerClientProvider.overrideWithValue(RecordingFluxerClient(api)),
        currentUserIdProvider.overrideWithValue(_userId),
      ],
    );
    addTearDown(container.dispose);
    store = container.read(syncedPreferencesStoreProvider);
  });

  Future<EmojiPins> storedPins() =>
      database.userPreferencesDao.getEmojiPins(_userId);

  test('the fork registers the pins field', () {
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
    expect(fields, contains(SyncedPreferenceField.emojiPins));
    expect(SyncedPreferenceField.emojiPins.fieldNumber, 2200);
  });

  test('takes the pins from the blob, and sends nothing back', () async {
    await store.hydrateFromUserSettings(
      syncedPreferencesUserSettings(
        _blob(
          pinned: <String>['unicode:heart'],
          personas: <String, List<String>>{
            '1001': <String>['unicode:fox'],
          },
        ),
      ),
    );
    await flushSyncedPreferencesDebounce(store);

    final EmojiPins pins = await container.read(emojiPinsProvider.future);
    expect(pins.account, <String>['unicode:heart']);
    expect(pins.forPersona('1001'), <String>['unicode:fox']);
    expect(await storedPins(), pins);
    expect(api.pushes, isEmpty);
  });

  test('pushes two quick pins in one request, with the rest of the blob as '
      'it came', () async {
    await store.hydrateFromUserSettings(
      syncedPreferencesUserSettings(_blob(pinned: <String>['unicode:heart'])),
    );
    final EmojiPinsNotifier notifier = container.read(
      emojiPinsProvider.notifier,
    );

    expect(await notifier.togglePin('unicode:tada'), isTrue);
    expect(await notifier.togglePin('unicode:fox', personaId: '1001'), isTrue);
    await flushSyncedPreferencesDebounce(store);

    expect(api.pushes, hasLength(1));
    expect(api.lastPush.emojiPins.pinnedEmojiIds, <String>[
      'unicode:heart',
      'unicode:tada',
    ]);
    expect(api.lastPush.emojiPins.personaPins['1001']?.emojiIds, <String>[
      'unicode:fox',
    ]);
    expect(api.lastPush.sidebar.inlineDmsCollapsed, isTrue);
  });

  test('pushes the last unpin as an empty message, not as a missing '
      'field', () async {
    await store.hydrateFromUserSettings(
      syncedPreferencesUserSettings(_blob(pinned: <String>['unicode:heart'])),
    );

    await container.read(emojiPinsProvider.notifier).togglePin('unicode:heart');
    await flushSyncedPreferencesDebounce(store);

    expect(api.pushes, hasLength(1));
    expect(api.lastPush.hasEmojiPins(), isTrue);
    expect(api.lastPush.emojiPins.pinnedEmojiIds, isEmpty);
  });

  test('follows another device clearing every pin', () async {
    await store.hydrateFromUserSettings(
      syncedPreferencesUserSettings(_blob(pinned: <String>['unicode:heart'])),
    );
    await store.hydrateFromUserSettings(
      syncedPreferencesUserSettings(_blob(pinned: <String>[])),
    );

    expect(await storedPins(), EmojiPins.empty);
    expect((await container.read(emojiPinsProvider.future)).account, isEmpty);
    expect(api.pushes, isEmpty);
  });

  test('keeps local pins when the blob has no pins field yet', () async {
    await database.userPreferencesDao.setEmojiPins(
      _userId,
      EmojiPins.empty.withPin('unicode:heart')!,
    );

    await store.hydrateFromUserSettings(syncedPreferencesUserSettings(_blob()));
    await flushSyncedPreferencesDebounce(store);

    expect((await storedPins()).account, <String>['unicode:heart']);
  });

  test('sends nothing for a pin that is refused', () async {
    await store.hydrateFromUserSettings(
      syncedPreferencesUserSettings(_blob(pinned: <String>[])),
    );

    expect(
      await container
          .read(emojiPinsProvider.notifier)
          .togglePin('unicode:dog', personaId: 'persona-a'),
      isFalse,
    );
    await flushSyncedPreferencesDebounce(store);

    expect(api.pushes, isEmpty);
  });

  test("drops a deleted persona's pins and pushes that once", () async {
    await store.hydrateFromUserSettings(
      syncedPreferencesUserSettings(
        _blob(
          pinned: <String>[],
          personas: <String, List<String>>{
            '1001': <String>['unicode:fox'],
          },
        ),
      ),
    );

    final EmojiPinsNotifier notifier = container.read(
      emojiPinsProvider.notifier,
    );
    await notifier.forgetPersona('1001');
    await notifier.forgetPersona('1001');
    await flushSyncedPreferencesDebounce(store);

    expect(api.pushes, hasLength(1));
    expect(api.lastPush.emojiPins.personaPins, isEmpty);
  });
}
