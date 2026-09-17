// Fork: tests the fork adds, kept out of upstream's message_item_cozy_test.dart so that file stays
// as upstream has it.
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/messages/message_item.dart';
import 'package:fluxer_app/features/members/domain/member.dart';
import 'package:fluxer_app/features/members/presentation/widgets/role_icon.dart';
import 'package:fluxer_app/features/settings/providers/preferences/chat_preferences_provider.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_app/shared/providers/member_icon_role_provider.dart';
import 'package:fluxer_dart/export.dart';

import '../../../../../helpers/message_item_test_overrides.dart';
import '../../../../../helpers/open_test_database.dart';
import 'message_item_cozy_test.dart' hide main;

const String _guildId = '1';
const String _authorId = '123456789012345678';

// Far wider than the row, as in tyne-chat/tyne#285.
final String _longName = 'A' * 80;

const MessageRenderSettings _guildSettings = MessageRenderSettings(
  activeGuildId: _guildId,
  renderEmbeds: false,
  renderReactions: false,
  inlineAttachmentMedia: false,
  renderSpoilers: RenderSpoilers.onClick,
  revealSpoilers: false,
  chatPreferences: ChatPreferencesState(),
  messageGroupSpacing: 16,
);

const MemberRole _iconRole = MemberRole(
  id: '2',
  name: 'Sparkles',
  color: 0,
  unicodeEmoji: '✨',
);

Message _message(String name, {bool isBot = false, int flags = 0}) {
  return Message(
    id: '3',
    channelId: 'c1',
    authorId: _authorId,
    authorName: name,
    authorIsBot: isBot,
    content: 'hello world',
    flags: flags,
    timestamp: DateTime(2026, 1, 1, 12),
  );
}

Future<void> _pumpRow(
  WidgetTester tester,
  Message message, {
  MemberRole? iconRole,
}) async {
  await tester.binding.setSurfaceSize(const Size(420, 640));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    forkUpstream.app(
      MessageItem(message: message, renderSettings: _guildSettings),
      overrides: [
        memberIconRoleProvider((
          _authorId,
          _guildId,
        )).overrideWithValue(iconRole),
      ],
    ),
  );
  await tester.pump();
}

double _timestampLeft(WidgetTester tester) =>
    tester.getTopLeft(find.textContaining('12:00')).dx;

void main() {
  setUp(() {
    forkUpstream.setDatabase(openTestDatabase());
  });

  group('MessageItem author header', () {
    messageItemTestWidgets(
      'a long name with a role icon stops before the timestamp',
      (WidgetTester tester) async {
        await _pumpRow(tester, _message(_longName), iconRole: _iconRole);

        final double timestampLeft = _timestampLeft(tester);
        expect(
          tester.getTopRight(find.textContaining('AAAA')).dx,
          lessThanOrEqualTo(timestampLeft),
        );
        expect(
          tester.getTopRight(find.byType(RoleIcon)).dx,
          lessThanOrEqualTo(timestampLeft),
        );
      },
    );

    messageItemTestWidgets(
      'a long name with a role icon and an author tag stops before the timestamp',
      (WidgetTester tester) async {
        await _pumpRow(
          tester,
          _message(_longName, flags: messageFlagIsCrosspost),
          iconRole: _iconRole,
        );

        expect(
          tester.getTopRight(find.textContaining('AAAA')).dx,
          lessThanOrEqualTo(_timestampLeft(tester)),
        );
      },
    );

    messageItemTestWidgets(
      'a long bot name with a role icon stops before the timestamp',
      (WidgetTester tester) async {
        await _pumpRow(
          tester,
          _message(_longName, isBot: true),
          iconRole: _iconRole,
        );

        expect(
          tester.getTopRight(find.textContaining('AAAA')).dx,
          lessThanOrEqualTo(_timestampLeft(tester)),
        );
      },
    );

    messageItemTestWidgets(
      'a long name without a role icon stops before the timestamp',
      (WidgetTester tester) async {
        await _pumpRow(tester, _message(_longName));

        expect(find.byType(RoleIcon), findsNothing);
        expect(
          tester.getTopRight(find.textContaining('AAAA')).dx,
          lessThanOrEqualTo(_timestampLeft(tester)),
        );
      },
    );

    messageItemTestWidgets('a short name keeps its role icon right after it', (
      WidgetTester tester,
    ) async {
      await _pumpRow(tester, _message('Alice'), iconRole: _iconRole);

      expect(
        tester.getTopLeft(find.byType(RoleIcon)).dx,
        tester.getTopRight(find.text('Alice')).dx + 4,
      );
    });
  });
}
