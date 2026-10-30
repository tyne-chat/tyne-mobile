// Fork: tests the fork adds, kept out of upstream's message_grouping_utils_test.dart so that file stays as
// upstream has it.
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/utils/messages/message_grouping_utils.dart';

import 'message_grouping_utils_test.dart' hide main;

Message _message({
  required String id,
  required String authorId,
  required String authorName,
  DateTime? timestamp,
  String? personaId,
  String? personaName,
  String? personaAvatar,
  String? personaTag,
  String? personaTagIcon,
}) {
  return forkUpstream
      .message(
        id: id,
        authorId: authorId,
        authorName: authorName,
        timestamp: timestamp,
      )
      .copyWith(
        personaId: personaId,
        personaName: personaName,
        personaAvatar: personaAvatar,
        personaTag: personaTag,
        personaTagIcon: personaTagIcon,
      );
}

void main() {
  group('grouping around server command messages', () {
    final DateTime start = DateTime.utc(2026, 10, 30, 12);
    Message row(String id, int minute, {String? commandId}) => _message(
      id: id,
      authorId: 'author-1',
      authorName: 'Chiara',
      timestamp: start.add(Duration(minutes: minute)),
    ).copyWith(commandId: commandId, commandName: commandId);

    test('a command message starts a new group after the same author', () {
      expect(
        isNewMessageGroup(row('2', 1, commandId: 'c'), row('1', 0)),
        isTrue,
      );
    });

    test('the message after a command message starts a new group', () {
      expect(
        isNewMessageGroup(row('2', 1), row('1', 0, commandId: 'c')),
        isTrue,
      );
    });

    test('ordinary messages still group', () {
      expect(isNewMessageGroup(row('2', 1), row('1', 0)), isFalse);
    });
  });

  TestWidgetsFlutterBinding.ensureInitialized();

  group('shouldGroupMessages', () {
    test('does not group when transitioning from root account to persona', () {
      final Message first = _message(
        id: '1',
        authorId: 'user',
        authorName: 'Alice',
      );
      final Message second = _message(
        id: '2',
        authorId: 'user',
        authorName: 'Alice',
        personaId: 'p1',
        personaName: 'Persona 1',
        personaTag: 'SYS',
        timestamp: DateTime.utc(2026, 1, 1, 12, 1),
      );
      expect(shouldGroupMessages(second, first), isFalse);
    });

    test(
      'does not group when transitioning from persona back to root account',
      () {
        final Message first = _message(
          id: '1',
          authorId: 'user',
          authorName: 'Alice',
          personaId: 'p1',
          personaName: 'Persona 1',
          personaTag: 'SYS',
        );
        final Message second = _message(
          id: '2',
          authorId: 'user',
          authorName: 'Alice',
          timestamp: DateTime.utc(2026, 1, 1, 12, 1),
        );
        expect(shouldGroupMessages(second, first), isFalse);
      },
    );

    test(
      'does not group consecutive messages from different personas of same user',
      () {
        final Message first = _message(
          id: '1',
          authorId: 'user',
          authorName: 'Alice',
          personaId: 'p1',
          personaName: 'Persona 1',
          personaTag: 'SYS',
        );
        final Message second = _message(
          id: '2',
          authorId: 'user',
          authorName: 'Alice',
          personaId: 'p2',
          personaName: 'Persona 2',
          personaTag: 'SYS',
          timestamp: DateTime.utc(2026, 1, 1, 12, 1),
        );
        expect(shouldGroupMessages(second, first), isFalse);
      },
    );

    test('groups consecutive messages from the same persona', () {
      final Message first = _message(
        id: '1',
        authorId: 'user',
        authorName: 'Alice',
        personaId: 'p1',
        personaName: 'Persona 1',
        personaAvatar: 'avatar_1',
        personaTag: 'SYS',
      );
      final Message second = _message(
        id: '2',
        authorId: 'user',
        authorName: 'Alice',
        personaId: 'p1',
        personaName: 'Persona 1',
        personaAvatar: 'avatar_1',
        personaTag: 'SYS',
        timestamp: DateTime.utc(2026, 1, 1, 12, 1),
      );
      expect(shouldGroupMessages(second, first), isTrue);
    });

    test('does not group if persona avatar differs', () {
      final Message first = _message(
        id: '1',
        authorId: 'user',
        authorName: 'Alice',
        personaId: 'p1',
        personaName: 'Persona 1',
        personaAvatar: 'avatar_a',
      );
      final Message second = _message(
        id: '2',
        authorId: 'user',
        authorName: 'Alice',
        personaId: 'p1',
        personaName: 'Persona 1',
        personaAvatar: 'avatar_b',
        timestamp: DateTime.utc(2026, 1, 1, 12, 1),
      );
      expect(shouldGroupMessages(second, first), isFalse);
    });

    test('does not group if persona tag differs', () {
      final Message first = _message(
        id: '1',
        authorId: 'user',
        authorName: 'Alice',
        personaId: 'p1',
        personaName: 'Persona 1',
        personaTag: 'TAG_A',
      );
      final Message second = _message(
        id: '2',
        authorId: 'user',
        authorName: 'Alice',
        personaId: 'p1',
        personaName: 'Persona 1',
        personaTag: 'TAG_B',
        timestamp: DateTime.utc(2026, 1, 1, 12, 1),
      );
      expect(shouldGroupMessages(second, first), isFalse);
    });

    test('does not group if persona tag icon differs', () {
      final Message first = _message(
        id: '1',
        authorId: 'user',
        authorName: 'Alice',
        personaId: 'p1',
        personaName: 'Persona 1',
        personaTag: 'TAG_A',
        personaTagIcon: 'https://example.com/icon1.png',
      );
      final Message second = _message(
        id: '2',
        authorId: 'user',
        authorName: 'Alice',
        personaId: 'p1',
        personaName: 'Persona 1',
        personaTag: 'TAG_A',
        personaTagIcon: 'https://example.com/icon2.png',
        timestamp: DateTime.utc(2026, 1, 1, 12, 1),
      );
      expect(shouldGroupMessages(second, first), isFalse);
    });
  });
}
