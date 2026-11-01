import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fluxer_app/core/instance/instance_runtime_config.dart';
import 'package:fluxer_app/features/chat/data/attachment_upload_client.dart';

/// Answers plans and uploads without a network. Set [gate] to hold every upload until it completes,
/// and [failUploads] to make them fail.
class FakeAttachmentUploadClient extends AttachmentUploadClient {
  FakeAttachmentUploadClient({required super.apiDio, required super.uploadDio});

  Completer<void>? gate;
  bool failUploads = false;
  int planRequests = 0;

  @override
  Future<AttachmentUploadPlan> requestAttachmentUploadPlan({
    required String channelId,
    required int attachmentId,
    required String filename,
    required int fileSize,
    required String contentType,
    CancelToken? cancelToken,
  }) async {
    planRequests += 1;
    return SingleAttachmentUploadPlan(
      uploadFilename: 'stored-$filename',
      fileSize: fileSize,
      contentType: contentType,
      uploadUrl: 'https://upload.test/file',
    );
  }

  @override
  Future<void> uploadAttachmentPlan(UploadAttachmentPlanParams params) async {
    params.onPlanReady?.call(
      uploadFilename: params.plan.uploadFilename,
      fileSize: params.plan.fileSize,
      contentType: params.plan.contentType,
    );
    final Completer<void>? held = gate;
    if (held != null) {
      await Future.any(<Future<void>>[
        held.future,
        params.cancelToken!.whenCancel.then((DioException e) => throw e),
      ]);
    }
    if (failUploads) {
      throw Exception('upload failed');
    }
  }
}

/// [InstanceRuntimeConfig.defaults] with presigned uploads on or off.
InstanceRuntimeConfig testInstanceRuntimeConfig({
  required bool presignedAttachmentUploads,
}) {
  const InstanceRuntimeConfig defaults = InstanceRuntimeConfig.defaults;
  return InstanceRuntimeConfig(
    productName: defaults.productName,
    selfHosted: defaults.selfHosted,
    stripeEnabled: defaults.stripeEnabled,
    emailsEnabled: defaults.emailsEnabled,
    voiceEnabled: defaults.voiceEnabled,
    presignedAttachmentUploads: presignedAttachmentUploads,
    gifEnabled: defaults.gifEnabled,
    blueskyEnabled: defaults.blueskyEnabled,
    gifAttributionRequired: defaults.gifAttributionRequired,
    singleCommunity: defaults.singleCommunity,
    directMessagesDisabled: defaults.directMessagesDisabled,
    registrationClosed: defaults.registrationClosed,
    adminRegistrationUrlsEnabled: defaults.adminRegistrationUrlsEnabled,
    collectDateOfBirth: defaults.collectDateOfBirth,
    premiumEnabled: defaults.premiumEnabled,
    usernameSignIn: defaults.usernameSignIn,
    uniqueUsernames: defaults.uniqueUsernames,
    guildCreateAccess: defaults.guildCreateAccess,
    discoveryEnabled: defaults.discoveryEnabled,
    serverListButtons: defaults.serverListButtons,
    iconUrl: defaults.iconUrl,
    symbolUrl: defaults.symbolUrl,
    logoUrl: defaults.logoUrl,
    wordmarkUrl: defaults.wordmarkUrl,
    themeColorHex: defaults.themeColorHex,
    gifDisplayName: defaults.gifDisplayName,
    singleCommunityGuildId: defaults.singleCommunityGuildId,
    premiumProductName: defaults.premiumProductName,
  );
}
