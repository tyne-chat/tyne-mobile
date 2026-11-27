import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/providers/instance/well_known_provider.dart';
import 'package:fluxer_app/features/gifts/providers/gift_embed_provider.dart';
import 'package:fluxer_app/features/gifts/utils/gift_code_utils.dart';
import 'package:fluxer_app/features/gifts/utils/gift_duration_text.dart';
import 'package:fluxer_app/features/gifts/utils/gift_redeem_errors.dart';
import 'package:fluxer_app/features/settings/presentation/sheets/claim_account_sheet.dart';
import 'package:fluxer_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:fluxer_app/features/ui/modal/fluxer_modal.dart';
import 'package:fluxer_app/features/ui/toast/fluxer_toast.dart';
import 'package:fluxer_app/features/ui/toast/toast_provider.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_app/shared/utils/api_error_presentation.dart';
import 'package:fluxer_app/shared/utils/clipboard_utils.dart';
import 'package:fluxer_dart/export.dart';

Future<bool> redeemGiftCode({
  required BuildContext context,
  required WidgetRef ref,
  required String code,
  VoidCallback? onSuccess,
}) async {
  final l10n = FluxerLocalizations.of(context);
  final settings = ref.read(userSettingsViewModelProvider);
  if (settings.isKnownUnclaimed) {
    await ClaimAccountSheet.show(context, ref);
    return false;
  }

  final normalizedCode = extractGiftCode(code);
  // Fork: pre-capture container before `_inAppClaimCheck` so caller unmount
  // during the check/redeem request does not throw StateError
  // (tyne-chat/tyne#946).
  final ProviderContainer container = ref.container;
  switch (await _inAppClaimCheck(container, normalizedCode)) {
    case _InAppClaimCheck.allowed:
      break;
    case _InAppClaimCheck.blocked:
      if (context.mounted) {
        await _showErrorModal(
          context,
          title: l10n.giftVisionaryCannotRedeemTitle,
          description: l10n.giftAcceptLifetimeNotInApp,
        );
      }
      return false;
    case _InAppClaimCheck.unknown:
      if (context.mounted) {
        await _showErrorModal(
          context,
          title: l10n.giftRedeemFailedTitle,
          description: l10n.giftRedeemFailedMessage,
        );
      }
      return false;
  }
  final ProviderSubscription<AsyncValue<GiftEmbedState>> gift = container
      .listen(giftEmbedProvider(normalizedCode), (_, _) {});
  try {
    await container.read(giftEmbedProvider(normalizedCode).notifier).redeem();
    if (!context.mounted) {
      return true;
    }
    container
        .read(toastProvider.notifier)
        .show(
          FluxerToast(
            message: l10n.giftRedeemedToast,
            variant: FluxerToastVariant.success,
          ),
        );
    onSuccess?.call();
    return true;
  } on DioException catch (error) {
    if (!context.mounted) {
      return false;
    }
    await _showRedeemFailure(
      context: context,
      container: container,
      code: normalizedCode,
      failure: giftRedeemFailureFromDio(error),
      l10n: l10n,
    );
    return false;
  } on Object {
    if (!context.mounted) {
      return false;
    }
    await _showErrorModal(
      context,
      title: l10n.giftRedeemFailedTitle,
      description: l10n.giftRedeemFailedMessage,
    );
    return false;
  } finally {
    gift.close();
  }
}

enum _InAppClaimCheck { allowed, blocked, unknown }

Future<_InAppClaimCheck> _inAppClaimCheck(
  ProviderContainer container,
  String code,
) async {
  if (defaultTargetPlatform != TargetPlatform.iOS) {
    return _InAppClaimCheck.allowed;
  }
  try {
    final GiftCodeResponse gift = await container
        .read(fluxerClientProvider)
        .gifts
        .getGiftCode(code: code);
    return giftClaimBlockedInApp(gift)
        ? _InAppClaimCheck.blocked
        : _InAppClaimCheck.allowed;
  } on DioException catch (error) {
    return error.response?.statusCode == 404
        ? _InAppClaimCheck.allowed
        : _InAppClaimCheck.unknown;
  } on Object {
    return _InAppClaimCheck.unknown;
  }
}

Future<void> _showRedeemFailure({
  required BuildContext context,
  required ProviderContainer container,
  required String code,
  required GiftRedeemFailure failure,
  required FluxerLocalizations l10n,
}) async {
  final notifier = container.read(giftEmbedProvider(code).notifier);

  switch (failure) {
    case GiftRedeemFailure.alreadyRedeemed:
      notifier.markRedeemed();
      await _showErrorModal(
        context,
        title: l10n.giftRedeemAlreadyRedeemedTitle,
        description: l10n.giftRedeemAlreadyRedeemedMessage,
      );
    case GiftRedeemFailure.invalid:
      notifier.markNotFound();
      await _showErrorModal(
        context,
        title: l10n.giftRedeemInvalidTitle,
        description: l10n.giftRedeemInvalidMessage,
      );
    case GiftRedeemFailure.notFound:
      notifier.markNotFound();
      await _showErrorModal(
        context,
        title: l10n.giftRedeemNotFoundTitle,
        description: l10n.giftRedeemNotFoundMessage,
      );
    case GiftRedeemFailure.visionaryCannotRedeem:
      await FluxerModal.show<void>(
        context,
        title: l10n.giftVisionaryCannotRedeemTitle,
        description: l10n.giftVisionaryCannotRedeemMessage,
        centered: true,
        actionsBuilder: (pop) => [
          TextButton(
            onPressed: () async {
              await copyToClipboard(
                context: context,
                value: giftShareUrl(
                  giftBaseUrl: container.read(instanceGiftBaseUrlProvider),
                  code: code,
                ),
              );
              pop();
            },
            child: Text(l10n.giftCopyLink),
          ),
        ],
        builder: (_, _) => const SizedBox.shrink(),
      );
    case GiftRedeemFailure.generic:
      await _showErrorModal(
        context,
        title: l10n.giftRedeemFailedTitle,
        description: l10n.giftRedeemFailedMessage,
      );
  }
}

Future<void> _showErrorModal(
  BuildContext context, {
  required String title,
  required String description,
}) {
  return showErrorDialog(context, title: title, body: description);
}
