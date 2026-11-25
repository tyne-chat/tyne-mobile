// Fork (tyne-chat/tyne#887): tests for per-embed mature flag preservation in
// `embed_gallery_utils.dart`, kept out of upstream's `embed_gallery_utils_test.dart`.

import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/instance/instance_endpoints.dart';
import 'package:fluxer_app/features/chat/domain/media_options_launch_context.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/utils/embeds/embed_gallery_utils.dart';
import 'package:fluxer_app/features/ui/media_viewer/attachment_media_viewer.dart';
import 'package:fluxer_app/features/ui/media_viewer/fork_viewer_items.dart';

void main() {
  const String mediaBase = 'https://media.tyne.test';
  const String postUrl = 'https://example.test/post/1';

  group('grouped embed mature flag preservation', () {
    test(
      'preserves per-embed nsfw flag through EmbedGalleryIndex -> resolveDisplay '
      '-> buildGalleryAttachments while keeping Attachment.url proxied',
      () {
        const Embed safeEmbed = Embed(
          type: EmbedType.link,
          url: postUrl,
          title: 'Mixed gallery',
          nsfw: false,
          image: EmbedMedia(
            url: 'https://origin.example/safe.png',
            proxyUrl: '$mediaBase/external/sig1/safe.png',
            width: 800,
            height: 600,
          ),
        );
        const Embed matureEmbed = Embed(
          type: EmbedType.link,
          url: postUrl,
          nsfw: true,
          image: EmbedMedia(
            url: 'https://origin.example/mature.png',
            proxyUrl: '$mediaBase/external/sig2/mature.png',
            width: 800,
            height: 600,
          ),
        );

        final EmbedGalleryIndex index = EmbedGalleryIndex(<Embed>[
          safeEmbed,
          matureEmbed,
        ]);
        final EmbedGalleryDisplay display = index.resolveDisplay(
          embedIndex: 0,
          hasAnyMedia: true,
        );
        expect(display.showGallery, isTrue);

        final List<Attachment> attachments = buildGalleryAttachments(
          images: display.galleryImages,
          embed: safeEmbed,
          embedIndex: 0,
        );
        expect(attachments, hasLength(2));
        expect(attachments[0].isMatureMedia, isFalse);
        expect(attachments[1].isMatureMedia, isTrue);
        // Proxy URL is preserved on both `url` and `proxyUrl` so viewer
        // open-in-browser / share links do not bypass the media proxy.
        expect(attachments[0].url, '$mediaBase/external/sig1/safe.png');
        expect(attachments[1].url, '$mediaBase/external/sig2/mature.png');
        expect(attachments[1].proxyUrl, '$mediaBase/external/sig2/mature.png');
      },
    );

    test(
      'preserves external original downloadUrl with query params when gallery proxyUrl is transformed',
      () {
        final String activeMediaBase = InstanceEndpoints.media;
        const String externalOriginal =
            'https://cdn.example.com/photo.jpg?width=1600&format=jpg&sig=abc';
        final String transformedProxy =
            '$activeMediaBase/external/sig9/photo.jpg?format=webp&width=800';

        final Embed embed1 = Embed(
          type: EmbedType.link,
          url: postUrl,
          title: 'Gallery with transformed proxy',
          image: EmbedMedia(
            url: externalOriginal,
            proxyUrl: transformedProxy,
            width: 1600,
            height: 1200,
          ),
        );
        final Embed embed2 = Embed(
          type: EmbedType.link,
          url: postUrl,
          image: EmbedMedia(
            url: 'https://cdn.example.com/photo2.png?width=1200',
            proxyUrl: '$activeMediaBase/external/sig10/photo2.png',
            width: 1200,
            height: 900,
          ),
        );

        final EmbedGalleryIndex index = EmbedGalleryIndex(<Embed>[
          embed1,
          embed2,
        ]);
        final EmbedGalleryDisplay display = index.resolveDisplay(
          embedIndex: 0,
          hasAnyMedia: true,
        );
        final List<Attachment> attachments = buildGalleryAttachments(
          images: display.galleryImages,
          embed: embed1,
          embedIndex: 0,
        );
        final List<AttachmentMediaViewerItem> viewerItems =
            forkViewerItemsFromAttachments(attachments);

        // Display/share URL stays proxied for privacy, while Download resolves
        // to the untransformed original external URL (even with its own width/format query)!
        expect(viewerItems[0].url, transformedProxy);
        expect(viewerItems[0].downloadUrl, externalOriginal);
        // Reverse-image search must keep using the proxied URL rather than
        // leaking the preserved external origin + query signature (F-041).
        final MediaOptionsLaunchContext context0 =
            MediaOptionsLaunchContext.fromImageViewerItem(viewerItems[0]);
        expect(context0.downloadUrl, externalOriginal);
        expect(context0.reverseImageSearchUrl, transformedProxy);

        // Untransformed proxy is still preferred when proxyUrl has no transform params.
        expect(
          viewerItems[1].downloadUrl,
          '$activeMediaBase/external/sig10/photo2.png',
        );
        final MediaOptionsLaunchContext context1 =
            MediaOptionsLaunchContext.fromImageViewerItem(viewerItems[1]);
        expect(
          context1.downloadUrl,
          '$activeMediaBase/external/sig10/photo2.png',
        );
        expect(
          context1.reverseImageSearchUrl,
          '$activeMediaBase/external/sig10/photo2.png',
        );
      },
    );
  });
}
