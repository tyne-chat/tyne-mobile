// Fork: who may do what in a DM's threads (tyne-chat/tyne#699), through
// upstream's thread rules and the fork's DM actor. The server enforces the
// rules; the app only offers what they allow.
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/permissions/thread_permissions.dart';
import 'package:fluxer_app/features/channels/domain/channel.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/dm/domain/dm_conversation.dart';
import 'package:fluxer_app/features/threads/fork_dm_threads/dm_thread_providers.dart';
import 'package:fluxer_app/features/threads/fork_dm_threads/dm_threads.dart';
import 'package:fluxer_app/features/threads/presentation/create_thread_sheet.dart';

const String _me = '100';
const String _other = '300';
const String _dmId = '500';

DmConversation _dm({bool group = false, String? ownerId}) => DmConversation(
  id: _dmId,
  type: group ? ChannelType.groupDm.wireValue : ChannelType.dm.wireValue,
  recipientId: _other,
  recipientName: 'Other',
  lastMessage: '',
  lastMessageTime: DateTime.utc(2026, 11, 17),
  ownerId: ownerId,
);

Channel _thread({String ownerId = _me}) => Channel(
  id: '900',
  guildId: forkDmThreadGuildKey,
  name: 'Plans',
  type: ChannelType.publicThread,
  parentId: _dmId,
  ownerId: ownerId,
);

ThreadActorContext _context(
  DmConversation dm, {
  String threadOwnerId = _me,
  bool canStart = true,
}) {
  final ThreadActor actor = forkDmThreadActorFor(
    dm: dm,
    currentUserId: _me,
    canStart: canStart,
  )!;
  return forkDmThreadActorContext(
    actor: actor,
    thread: _thread(ownerId: threadOwnerId),
    dm: dm,
    currentUserId: _me,
    isMember: true,
  );
}

bool _mayRename(ThreadActorContext ctx) =>
    threadPatchRequirement(const ThreadPatch(name: true), 0, ctx) == null;

bool _mayClose(ThreadActorContext ctx) =>
    threadPatchRequirement(const ThreadPatch(archived: true), 0, ctx) == null;

void main() {
  group('a 1:1 DM', () {
    test('either person may rename and close a thread', () {
      for (final String starter in <String>[_me, _other]) {
        final ThreadActorContext ctx = _context(_dm(), threadOwnerId: starter);
        expect(_mayRename(ctx), isTrue, reason: 'started by $starter');
        expect(_mayClose(ctx), isTrue, reason: 'started by $starter');
      }
    });

    test('nobody moderates: no lock, delete or removing members', () {
      final ThreadActorContext ctx = _context(_dm());

      expect(isThreadModeratorFor(ctx), isFalse);
      expect(canDeleteThread(ctx), isNotNull);
      expect(canRemoveThreadMember(ctx), isNotNull);
    });

    test('only the starter is offered Delete', () {
      expect(
        forkDmStarterMayDeleteFor(
          thread: _thread(),
          dm: _dm(),
          currentUserId: _me,
        ),
        isTrue,
      );
      expect(
        forkDmStarterMayDeleteFor(
          thread: _thread(ownerId: _other),
          dm: _dm(),
          currentUserId: _me,
        ),
        isFalse,
      );
    });
  });

  group('a group DM', () {
    test('its owner moderates', () {
      final ThreadActorContext ctx = _context(
        _dm(group: true, ownerId: _me),
        threadOwnerId: _other,
      );

      expect(isThreadModeratorFor(ctx), isTrue);
      expect(canDeleteThread(ctx), isNull);
      expect(canRemoveThreadMember(ctx), isNull);
      expect(_mayRename(ctx), isTrue);
    });

    test('a starter may rename and close, but not lock or delete', () {
      final ThreadActorContext ctx = _context(
        _dm(group: true, ownerId: _other),
      );

      expect(_mayRename(ctx), isTrue);
      expect(_mayClose(ctx), isTrue);
      expect(isThreadModeratorFor(ctx), isFalse);
      expect(canDeleteThread(ctx), isNotNull);
      expect(
        forkDmStarterMayDeleteFor(
          thread: _thread(),
          dm: _dm(group: true, ownerId: _other),
          currentUserId: _me,
        ),
        isFalse,
      );
    });

    test('anyone else may neither rename nor close', () {
      final ThreadActorContext ctx = _context(
        _dm(group: true, ownerId: _other),
        threadOwnerId: _other,
      );

      expect(_mayRename(ctx), isFalse);
      expect(_mayClose(ctx), isFalse);
    });
  });

  group('starting threads', () {
    final Channel parent = forkDmThreadParentChannel(
      dmId: _dmId,
      isGroup: false,
      name: 'Other',
    );
    final Message message = Message(
      id: '700',
      channelId: _dmId,
      authorId: _other,
      authorName: 'Other',
      content: 'hello',
      timestamp: DateTime.utc(2026, 11, 17),
    );

    test('is offered only with READY switch on, and never private', () {
      final ThreadActor on = forkDmThreadActorFor(
        dm: _dm(),
        currentUserId: _me,
        canStart: true,
      )!;
      final ThreadActor off = forkDmThreadActorFor(
        dm: _dm(),
        currentUserId: _me,
        canStart: false,
      )!;

      expect(forkIsDmThreadParent(parent), isTrue);
      expect(canStartThreadIn(parent, on), isTrue);
      expect(canStartThreadIn(parent, off), isFalse);
      expect(allowsPrivateThreads(parent), isFalse);
      expect(
        canStartThreadFromMessage(parent: parent, message: message, actor: on),
        isTrue,
      );
      expect(
        canStartThreadFromMessage(parent: parent, message: message, actor: off),
        isFalse,
      );
    });

    test('a DM thread can be written in without the switch', () {
      final ThreadActorContext ctx = _context(_dm(), canStart: false);

      expect(threadWriteBlock(ThreadWriteAction.send, ctx), isNull);
      expect(canViewThread(ctx), isNull);
    });

    test('personal notes have no threads', () {
      expect(
        forkDmThreadActorFor(
          dm: DmConversation(
            id: _me,
            type: ChannelType.dmPersonalNotes.wireValue,
            recipientId: _me,
            recipientName: 'Me',
            lastMessage: '',
            lastMessageTime: DateTime.utc(2026, 11, 17),
          ),
          currentUserId: _me,
          canStart: true,
        ),
        isNull,
      );
    });
  });

  test('the browser names a DM without a hash', () {
    expect(
      forkThreadBrowserParentLabel(
        forkDmThreadParentChannel(dmId: _dmId, isGroup: true, name: 'Crew'),
      ),
      'Crew',
    );
    expect(
      forkThreadBrowserParentLabel(
        const Channel(id: '1', guildId: 'g1', name: 'general'),
      ),
      '#general',
    );
  });

  test('Back from a known DM thread goes to its DM', () {
    addTearDown(forkResetDmThreadIndex);
    forkNoteDmThread('900', _dmId);

    expect(forkDmThreadLeavePath('900'), '/channels/@me/$_dmId');
    expect(forkDmThreadLeavePath('2'), isNull);

    forkForgetDmThread('900');
    expect(forkDmThreadLeavePath('900'), isNull);
  });
}
