// Fork: tests the fork adds, kept out of upstream's message_test.dart so that file stays as
// upstream has it.

import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/constants/user_flags.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_dart/export.dart';

import 'message_test.dart' hide main;

MessageResponseSchema _sdkMessage({Map<String, Object?>? command}) {
  return MessageResponseSchema.fromJson(<String, Object?>{
    'id': '1',
    'channel_id': '2',
    'author': <String, Object?>{
      'id': '3',
      'username': 'author',
      'discriminator': '0',
      'global_name': null,
      'avatar': null,
      'avatar_color': null,
      'flags': 0,
    },
    'type': 0,
    'flags': 0,
    'content': 'text',
    'timestamp': '2026-10-30T00:00:00.000Z',
    'pinned': false,
    'mention_everyone': false,
    'command': ?command,
  });
}

void main() {
  group('a message made by a server command', () {
    Message made() => forkUpstream.message().copyWith(
      commandId: 'c1',
      commandGuildId: 'g1',
      commandName: 'tuck',
    );

    test('reads the command the server sends', () {
      final Message message = Message.fromSdk(
        _sdkMessage(
          command: <String, Object?>{
            'id': 'c1',
            'guild_id': 'g1',
            'name': 'tuck',
          },
        ),
      );
      expect(message.commandId, 'c1');
      expect(message.commandGuildId, 'g1');
      expect(message.commandName, 'tuck');
    });

    test('shows again from the cache', () {
      final companion = made().toCompanion();
      expect(companion.commandId.value, 'c1');
      expect(companion.commandGuildId.value, 'g1');
      expect(companion.commandName.value, 'tuck');
    });

    test('loses its chip when an edit comes without the command', () {
      final Message edited = made().applyGatewayUpdate(
        _sdkMessage(),
        isMentioned: false,
      );
      expect(edited.commandId, isNull);
      expect(edited.commandName, isNull);
    });

    test('redraws when the chip goes', () {
      expect(made().isRenderEquivalent(forkUpstream.message()), isFalse);
      expect(made().isRenderEquivalent(made()), isTrue);
    });

    test('a copy keeps the command, and can clear it', () {
      expect(made().copyWith(content: 'x').commandName, 'tuck');
      expect(made().copyWith(commandName: null).commandName, isNull);
    });
  });

  TestWidgetsFlutterBinding.ensureInitialized();

  group('Message persona and deleted author resolution', () {
    test(
      'isDeletedAuthor checks user flags without relying on spoofable username strings or synthetic IDs',
      () {
        final normal = forkUpstream.message().copyWith(
          authorName: 'Alice',
          authorPublicFlags: 0,
        );
        expect(normal.isDeletedAuthor, isFalse);

        final staff = forkUpstream.message().copyWith(
          authorName: 'Chiara',
          authorPublicFlags: kUserFlagStaff,
        );
        expect(staff.isDeletedAuthor, isFalse);

        // Users setting their name or nickname to "Deleted User" should not be marked as deleted authors
        final byName = forkUpstream.message().copyWith(
          authorName: 'Deleted User',
          authorPublicFlags: 0,
        );
        expect(byName.isDeletedAuthor, isFalse);

        final byId = forkUpstream.message().copyWith(
          authorId: '1',
          authorName: 'Someone',
          authorPublicFlags: 0,
        );
        expect(byId.isDeletedAuthor, isFalse);

        final byFlagDeleted = forkUpstream.message().copyWith(
          authorName: 'Alice',
          authorPublicFlags: kUserFlagDeleted,
        );
        expect(byFlagDeleted.isDeletedAuthor, isTrue);

        final byFlagSelfDeleted = forkUpstream.message().copyWith(
          authorName: 'Alice',
          authorPublicFlags: kUserFlagSelfDeleted,
        );
        expect(byFlagSelfDeleted.isDeletedAuthor, isTrue);
      },
    );

    test(
      'isPersona returns true for authors with persona attributes, including deleted authors',
      () {
        final normalUser = forkUpstream.message().copyWith(authorName: 'Alice');
        expect(normalUser.isPersona, isFalse);

        final personaUser = forkUpstream.message().copyWith(
          authorName: 'Alice',
          personaId: 'p1',
          personaName: 'Subprofile A',
        );
        expect(personaUser.isPersona, isTrue);

        final staffPersonaUser = personaUser.copyWith(
          authorName: 'Chiara',
          authorPublicFlags: kUserFlagStaff,
        );
        expect(staffPersonaUser.isPersona, isTrue);

        // Active user nicknamed "Deleted User" with active persona is not falsely stripped
        final nicknamedPersonaAuthor = personaUser.copyWith(
          authorName: 'Deleted User',
        );
        expect(nicknamedPersonaAuthor.isPersona, isTrue);

        // Flagged deleted root author with persona attributes preserves isPersona so it displays as "Deleted Persona"
        final flaggedDeletedAuthor = personaUser.copyWith(
          authorName: 'Deleted User',
          authorPublicFlags: kUserFlagDeleted,
          personaName: 'Deleted Persona',
        );
        expect(flaggedDeletedAuthor.isPersona, isTrue);
      },
    );
  });
}
