// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: a blocked persona's messages collapse as a blocked account's do
// (tyne-chat/tyne#921), and nobody else's.

import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/utils/messages/channel_message_stream.dart';
import 'package:fluxer_app/features/chat/utils/messages/fork_blocked_persona.dart';

Message _message(String id, String authorId, {String? personaId}) => Message(
  id: id,
  channelId: 'channel-1',
  authorId: authorId,
  authorName: authorId,
  content: 'hello',
  timestamp: DateTime.utc(2026, 1, 1, 12),
  personaId: personaId,
);

bool _neverSpammer(String userId, int userFlags) => false;

ChannelCollapseContext _context(Set<String> blockedPersonaKeys) =>
    ChannelCollapseContext(
      treatSpam: true,
      currentUserId: 'me',
      blockedUserIds: const <String>{},
      isUserMarkedAsSpammer: _neverSpammer,
      forkBlockedPersonaKeys: blockedPersonaKeys,
    );

void main() {
  final Set<String> blocked = <String>{personaBlockKey('sys', 'lyra')};

  test("collapses the blocked persona's messages into one blocked group", () {
    final List<ChannelStreamItem> stream = createChannelStream(
      messages: <Message>[
        _message('1', 'sys', personaId: 'lyra'),
        _message('2', 'sys', personaId: 'lyra'),
        _message('3', 'sys', personaId: 'vega'),
      ],
      oldestUnreadMessageId: null,
      context: _context(blocked),
    );
    final ChannelStreamItem group = stream.firstWhere(
      (ChannelStreamItem item) =>
          item.type == ChannelStreamType.messageGroupBlocked,
    );
    expect(group.messages.map((Message m) => m.id), <String>['1', '2']);
    expect(stream.where((item) => item.type.isCollapsedGroup).length, 1);
  });

  test('leaves the account itself, its other personas and the same persona '
      'id of another account alone', () {
    final ChannelCollapseContext context = _context(blocked);
    expect(context.collapsedTypeFor(_message('1', 'sys')), isNull);
    expect(
      context.collapsedTypeFor(_message('2', 'sys', personaId: 'vega')),
      isNull,
    );
    expect(
      context.collapsedTypeFor(_message('3', 'other', personaId: 'lyra')),
      isNull,
    );
    expect(
      context.collapsedTypeFor(_message('4', 'sys', personaId: 'lyra')),
      ChannelStreamType.messageGroupBlocked,
    );
  });

  test('with no blocked personas, nothing changes', () {
    expect(
      _context(
        const <String>{},
      ).collapsedTypeFor(_message('1', 'sys', personaId: 'lyra')),
      isNull,
    );
  });
}
