import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluxer_app/core/api/attachment_request_auth.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/media/media_thumb_hash_placeholder.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/media/retrying_network_image.dart';
import 'package:fluxer_app/features/chat/utils/attachments/attachment_display_utils.dart';
import 'package:fluxer_app/material_ui.dart';

// Fork imports.
// ignore: directives_ordering
import 'package:fluxer_app/features/ui/media_viewer/fork_observable_svg_image.dart';

class ChatNetworkImage extends StatelessWidget {
  const ChatNetworkImage({
    required this.imageUrl,
    this.forkOnImageLoaded,
    this.forkOnLoadFailure,
    this.forkMaxRetries,
    this.filename,
    this.contentType,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.memCacheWidth,
    this.memCacheHeight,
    this.placeholder,
    this.errorPlaceholder = const SizedBox.shrink(),
    super.key,
  });

  final VoidCallback? forkOnImageLoaded;
  final ForkImageLoadFailureCallback? forkOnLoadFailure;
  final int? forkMaxRetries;
  final String imageUrl;
  final String? filename;
  final String? contentType;
  final double? width;
  final double? height;
  final BoxFit fit;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final Widget? placeholder;
  final Widget errorPlaceholder;

  @override
  Widget build(BuildContext context) {
    final Widget? placeholder = this.placeholder;
    final Widget? boxedPlaceholder = placeholder == null
        ? null
        : SizedBox(width: width, height: height, child: placeholder);
    if (isSvgImageMedia(
      url: imageUrl,
      filename: filename,
      contentType: contentType,
    )) {
      // Fork: single-GET decode-verified SVG path when viewer readiness is observed.
      if (forkOnImageLoaded != null || forkOnLoadFailure != null) {
        return ForkObservableSvgNetworkImage(
          imageUrl: imageUrl,
          width: width,
          height: height,
          fit: fit,
          placeholder: boxedPlaceholder,
          errorPlaceholder: errorPlaceholder,
          onLoaded: forkOnImageLoaded,
          onLoadFailure: forkOnLoadFailure,
        );
      }
      return SvgPicture.network(
        imageUrl,
        headers: AttachmentRequestAuth.headersFor(imageUrl),
        width: width,
        height: height,
        fit: fit,
        placeholderBuilder: boxedPlaceholder == null
            ? null
            : (_) => boxedPlaceholder,
        errorBuilder: (_, _, _) => errorPlaceholder,
      );
    }
    return RetryingNetworkImage(
      forkOnImageLoaded: forkOnImageLoaded,
      forkOnLoadFailure: forkOnLoadFailure,
      forkMaxRetries: forkMaxRetries,
      imageUrl: imageUrl,
      width: width,
      height: height,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      fit: fit,
      fadeOutDuration: boxedPlaceholder == null
          ? Duration.zero
          : mediaPlaceholderFadeOutOf(context),
      disablePlaceholderOnCacheHit: boxedPlaceholder == null,
      placeholder: boxedPlaceholder,
      errorPlaceholder: errorPlaceholder,
    );
  }
}
