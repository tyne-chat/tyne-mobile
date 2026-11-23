import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/providers/app/account_user_id.dart';
import 'package:fluxer_app/features/chat/providers/upload/cloud_upload_controller.dart';
import 'package:fluxer_markdown/fluxer_markdown.dart';

// Fork imports.
// ignore: directives_ordering
import 'package:fluxer_app/features/chat/utils/composer/fork_edit_sendable.dart';

bool composerHasSendableContent(
  WidgetRef ref,
  String channelId,
  String wireText,
) {
  final bool hasPendingUploads = ref
      .read(cloudUploadControllerProvider(readAccountUserId(ref), channelId))
      .items
      .isNotEmpty;
  // Fork: while a message is being edited, the edit rules decide (tyne-chat/tyne#904).
  final bool? forkEdit = forkEditHasSendableContent(
    ref,
    wireText,
    hasPendingUploads: hasPendingUploads,
  );
  if (forkEdit != null) {
    return channelId.isNotEmpty && forkEdit;
  }
  return composerHasSendableContentFromParts(
    channelId: channelId,
    wireText: wireText,
    hasPendingUploads: hasPendingUploads,
  );
}

bool composerHasSendableContentFromParts({
  required String channelId,
  required String wireText,
  required bool hasPendingUploads,
}) {
  if (channelId.isEmpty) {
    return false;
  }
  return hasVisibleContent(wireText) || hasPendingUploads;
}
