// Fork: tests the fork adds, kept out of upstream's DM tests so those files stay as upstream has them.

import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/features/chat/providers/composer/composer_watch_provider.dart';
import 'package:fluxer_app/features/dm/domain/dm_channel_types.dart';
import 'package:fluxer_app/features/dm/domain/dm_conversation.dart';
import 'package:fluxer_app/features/profile/domain/imported_placeholder.dart';

db.DmChannel _row() => db.DmChannel(
  id: '100',
  recipientId: '2',
  type: 1,
  recipientCount: 2,
  recipientIds: '["1","2"]',
  nicksJson: '{}',
  lastMessage: '',
  lastMessageTime: DateTime.utc(2026),
  unreadCount: 0,
  nsfw: false,
);

db.User _user({int? publicFlags}) => db.User(
  id: '2',
  username: 'lemon_muffin',
  discriminator: '0001',
  bot: false,
  system: false,
  status: 'offline',
  mobile: false,
  hiddenProfileBadgesJson: '[]',
  publicFlags: publicFlags,
);

void main() {
  // tyne-chat/tyne#685: a DM the Discord import made with a placeholder for someone not on Tyne.
  group('a DM with a Discord import placeholder', () {
    test('knows it from the recipient’s public flags, and offers no call', () {
      final DmConversation dm = DmConversation.fromRow(
        _row(),
        _user(publicFlags: kForkUserFlagImported),
      );
      expect(dm.forkImportedRecipient, isTrue);
      expect(canStartDmCall(dm), isFalse);
      expect(dm.withUnreadCount(3).forkImportedRecipient, isTrue);
    });

    test('another DM is as before', () {
      final DmConversation dm = DmConversation.fromRow(_row(), _user());
      expect(dm.forkImportedRecipient, isFalse);
      expect(canStartDmCall(dm), isTrue);
    });

    test('the composer is told', () {
      final ComposerWatch? watch = composerWatchFor(
        DmConversation.fromRow(
          _row(),
          _user(publicFlags: kForkUserFlagImported),
        ),
      );
      expect(watch?.forkImportedRecipient, isTrue);
    });
  });
}
