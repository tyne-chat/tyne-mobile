import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart'
    show FluxerDatabase;
import 'package:fluxer_app/core/permissions/permission.dart';
import 'package:fluxer_app/core/permissions/thread_permissions.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/features/channels/domain/channel.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/threads/presentation/create_thread_sheet.dart';
import 'package:fluxer_app/features/threads/providers/thread_ui_providers.dart';
import 'package:fluxer_app/features/threads/utils/thread_name_from_message.dart';
import 'package:fluxer_app/material_ui.dart';

import '../../helpers/open_test_database.dart';
import '../../helpers/test_l10n.dart';

// tyne-chat/tyne#100: a thread started from a message with a custom emoji was
// named with the emoji's markup, `<:BlushHide:1549583995778367498>`.
void main() {
  group('threadNameFromMessageContent', () {
    test('writes custom emoji as :name:, animated ones too', () {
      expect(
        threadNameFromMessageContent(
          'Me! Also me! <:BlushHide:1549583995778367498> <a:spin:1549583995778367499>',
        ),
        'Me! Also me! :BlushHide: :spin:',
      );
    });

    test('keeps the text on one line, trimmed', () {
      expect(threadNameFromMessageContent('  one\ntwo  '), 'one two');
    });

    test('leaves other text as it is', () {
      expect(threadNameFromMessageContent('a <b> :c: <@1>'), 'a <b> :c: <@1>');
    });
  });

  testWidgets('the create thread sheet suggests the name without emoji '
      'markup', (WidgetTester tester) async {
    const String guildId = '800';
    const String parentId = '1500';
    final FluxerDatabase database = openTestDatabase();
    addTearDown(database.close);
    final colorTheme = buildDarkColorTheme();
    final Message source = Message(
      id: '1600',
      channelId: parentId,
      authorId: '42',
      authorName: 'Fullest',
      content: 'Me! Also me! <:BlushHide:1549583995778367498>',
      timestamp: DateTime.utc(2026, 10, 16, 12),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fluxerDatabaseProvider.overrideWithValue(database),
          parentThreadActorProvider(guildId, parentId).overrideWithValue(
            ThreadActor(
              permissions:
                  Permission.viewChannel.value |
                  Permission.sendMessages.value |
                  Permission.createPublicThreads.value,
            ),
          ),
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
          home: Scaffold(
            body: Consumer(
              builder: (BuildContext context, WidgetRef ref, _) => Center(
                child: ElevatedButton(
                  onPressed: () => showCreateThreadSheet(
                    context,
                    ref,
                    parent: const Channel(
                      id: parentId,
                      guildId: guildId,
                      name: 'general',
                    ),
                    sourceMessage: source,
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Me! Also me! :BlushHide:'), findsWidgets);
    expect(find.textContaining('<:BlushHide:'), findsNothing);
  });
}
