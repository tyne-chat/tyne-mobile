// Fork: tyne-chat/tyne#946 — regression test ensuring DM preview author prefix
// uses localized "You" for the active locale rather than hardcoded English.

import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/dm/domain/dm_conversation.dart';
import 'package:fluxer_app/features/dm/domain/dm_list_message_preview.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/material_ui.dart';

void main() {
  group('resolveDmListMessagePreview localized own prefix', () {
    late FluxerLocalizations esL10n;

    setUpAll(() async {
      esL10n = await FluxerLocalizations.delegate.load(const Locale('es'));
    });

    test(
      'uses localized You label for own text message in non-English locales',
      () {
        expect(esL10n.channelDetailsMemberYou, isNot('You'));
        final DmListMessagePreview? preview = resolveDmListMessagePreview(
          l10n: esL10n,
          conversation: DmConversation(
            id: '100',
            type: 1,
            recipientId: '200',
            recipientName: 'Monty',
            lastMessage: 'Hola',
            lastMessageAuthorId: '1',
            lastMessageAuthorName: 'Me',
            lastMessageTime: DateTime(2026),
          ),
          currentUserId: '1',
          authorFriendNickname: null,
        );

        expect(preview, isA<DmListMarkdownMessagePreview>());
        expect(
          (preview! as DmListMarkdownMessagePreview).authorPrefix,
          '${esL10n.channelDetailsMemberYou}: ',
        );
      },
    );

    test(
      'uses localized You label for own attachment message in non-English locales',
      () {
        final DmListMessagePreview? preview = resolveDmListMessagePreview(
          l10n: esL10n,
          conversation: DmConversation(
            id: '100',
            type: 1,
            recipientId: '200',
            recipientName: 'Monty',
            lastMessage: '',
            lastMessageAuthorId: '1',
            lastMessageAuthorName: 'Me',
            lastMessageHasAttachments: true,
            lastMessageTime: DateTime(2026),
          ),
          currentUserId: '1',
          authorFriendNickname: null,
        );

        expect(preview, isA<DmListAttachmentMessagePreview>());
        expect(
          (preview! as DmListAttachmentMessagePreview).authorPrefix,
          '${esL10n.channelDetailsMemberYou}: ',
        );
      },
    );
  });
}
