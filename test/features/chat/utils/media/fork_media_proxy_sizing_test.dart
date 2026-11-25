// Fork (tyne-chat/tyne#887): tests for single-width media-proxy thumbnail
// sizing, cross-repo ladder parity, URL trust scoping, and audio cover sizing.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/attachment_request_auth.dart';
import 'package:fluxer_app/core/audio/chat_attachment/chat_attachment_audio_controller.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/attachments/attachment_audio_card_fork.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/media/chat_network_image.dart';
import 'package:fluxer_app/features/chat/utils/attachments/attachment_cover_fork.dart';
import 'package:fluxer_app/features/chat/utils/media/fork_media_proxy_sizing.dart';
import 'package:fluxer_app/features/chat/utils/media/hdr_aware_image_url.dart';
import 'package:fluxer_app/features/settings/providers/preferences/appearance_preferences_provider.dart';
import 'package:fluxer_app/material_ui.dart';

import '../../../../helpers/test_l10n.dart';

List<int> _parseIntListFromBlock(String source, RegExp pattern) {
  final RegExpMatch? match = pattern.firstMatch(source);
  expect(match, isNotNull, reason: 'Failed to locate ladder in source');
  final String body = match!.group(1)!;
  final List<int> values = RegExp(
    r'\d+',
  ).allMatches(body).map((RegExpMatch m) => int.parse(m.group(0)!)).toList();
  expect(values, isNotEmpty);
  return values;
}

void main() {
  const String mediaBase = 'https://media.tyne.test';

  group('cross-repo image size ladder parity', () {
    test('matches fluxer/packages/constants/src/MediaProxyImageSizes.ts and '
        'fluxer/fluxer_media_proxy/src/constants.rs', () {
      final File tsFile = File(
        'fluxer/packages/constants/src/MediaProxyImageSizes.ts',
      );
      final File rsFile = File('fluxer/fluxer_media_proxy/src/constants.rs');
      expect(
        tsFile.existsSync(),
        isTrue,
        reason: 'Expected fluxer submodule TS constants file to exist',
      );
      expect(
        rsFile.existsSync(),
        isTrue,
        reason: 'Expected fluxer submodule Rust constants file to exist',
      );

      final List<int> tsSizes = _parseIntListFromBlock(
        tsFile.readAsStringSync(),
        RegExp(r'MEDIA_PROXY_IMAGE_SIZE_QUERY_VALUES\s*=\s*\[([\s\S]*?)\]'),
      );
      final List<int> rsSizes = _parseIntListFromBlock(
        rsFile.readAsStringSync(),
        RegExp(r'IMAGE_SIZES\s*:\s*&\[u32\]\s*=\s*&\[([\s\S]*?)\]'),
      );

      expect(kForkMediaProxyImageSizes, tsSizes);
      expect(kForkMediaProxyImageSizes, rsSizes);
    });
  });

  group('forkSanitizeDevicePixelRatio & forkSnapMediaProxyImageSize', () {
    test('sanitizes non-positive and non-finite DPR to 1', () {
      expect(forkSanitizeDevicePixelRatio(0), 1);
      expect(forkSanitizeDevicePixelRatio(-2), 1);
      expect(forkSanitizeDevicePixelRatio(double.nan), 1);
      expect(forkSanitizeDevicePixelRatio(double.infinity), 1);
      expect(forkSanitizeDevicePixelRatio(2.75), 2.75);
    });

    test(
      'snaps up by default and respects 10% downscale tolerance at DPR>=2',
      () {
        // 330 * 3 = 990 -> next rung 1024.
        expect(forkSnapMediaProxyImageSize(330, 3), 1024);
        // 360 * 3 = 1080; below is 1024; 1080 / 1024 = 1.054 <= 1.1 -> 1024 when allowed.
        expect(forkSnapMediaProxyImageSize(360, 3, allowDownscale: true), 1024);
        expect(forkSnapMediaProxyImageSize(360, 3), 1280);
        // At DPR < 2, downscale tolerance is disabled.
        expect(
          forkSnapMediaProxyImageSize(1080, 1, allowDownscale: true),
          1280,
        );
        // Caps at maxDimension.
        expect(forkSnapMediaProxyImageSize(10000, 2, maxDimension: 8192), 8192);
      },
    );
  });

  group('forkResolveProxyRequestWidth', () {
    test(
      'returns null when source or layout dimensions are missing/invalid',
      () {
        expect(
          forkResolveProxyRequestWidth(
            layoutWidth: 300,
            layoutHeight: 200,
            devicePixelRatio: 3,
            sourceWidth: null,
            sourceHeight: 1000,
          ),
          isNull,
        );
        expect(
          forkResolveProxyRequestWidth(
            layoutWidth: 300,
            layoutHeight: 200,
            devicePixelRatio: 3,
            sourceWidth: 1000,
            sourceHeight: 0,
          ),
          isNull,
        );
        expect(
          forkResolveProxyRequestWidth(
            layoutWidth: double.infinity,
            layoutHeight: 200,
            devicePixelRatio: 3,
            sourceWidth: 4000,
            sourceHeight: 3000,
          ),
          isNull,
        );
      },
    );

    test('never upscales small images', () {
      expect(
        forkResolveProxyRequestWidth(
          layoutWidth: 300,
          layoutHeight: 200,
          devicePixelRatio: 3,
          sourceWidth: 400,
          sourceHeight: 300,
        ),
        isNull,
      );
    });

    test('uses ceil on scaled width for contain layout', () {
      // 4000x3000 in 300x225 at dpr 3 -> longest edge 900 -> snaps to 1024 -> width = 1024.
      expect(
        forkResolveProxyRequestWidth(
          layoutWidth: 300,
          layoutHeight: 225,
          devicePixelRatio: 3,
          sourceWidth: 4000,
          sourceHeight: 3000,
        ),
        1024,
      );
      // Portrait 3000x4000 in 225x300 at dpr 3 -> longest edge 900 -> snaps to 1024
      // scale = 1024 / 4000 = 0.256 -> width = (3000 * 0.256).ceil() = 768.
      expect(
        forkResolveProxyRequestWidth(
          layoutWidth: 225,
          layoutHeight: 300,
          devicePixelRatio: 3,
          sourceWidth: 3000,
          sourceHeight: 4000,
        ),
        768,
      );
      // Landscape sweep over common camera widths never overshoots ladder rung by +1 px.
      for (final int cameraWidth in const <int>[
        1920,
        2560,
        3840,
        4000,
        4032,
        4080,
        4608,
        5472,
        6000,
        8064,
      ]) {
        final int cameraHeight = (cameraWidth * 3) ~/ 4;
        final int? w = forkResolveProxyRequestWidth(
          layoutWidth: 300,
          layoutHeight: 225,
          devicePixelRatio: 3,
          sourceWidth: cameraWidth,
          sourceHeight: cameraHeight,
        );
        expect(w, 1024, reason: 'cameraWidth=$cameraWidth');
      }
    });

    test('accounts for BoxFit.cover cropping and panorama clamp', () {
      // 4000x2000 (2:1) in 150x150 square at dpr 2 -> effectiveWidth = 300 -> 600 px.
      final int? landscapeCover = forkResolveProxyRequestWidth(
        layoutWidth: 150,
        layoutHeight: 150,
        devicePixelRatio: 2,
        sourceWidth: 4000,
        sourceHeight: 2000,
        cover: true,
        maxCoverAspectMultiplier: 2,
      );
      expect(landscapeCover, 600);

      // 2000x4000 (1:2) portrait in 150x150 square at dpr 2 -> effectiveHeight = 300 -> 600 px -> width 300.
      final int? portraitCover = forkResolveProxyRequestWidth(
        layoutWidth: 150,
        layoutHeight: 150,
        devicePixelRatio: 2,
        sourceWidth: 2000,
        sourceHeight: 4000,
        cover: true,
        maxCoverAspectMultiplier: 2,
      );
      expect(portraitCover, 300);

      // Extreme 10:1 panorama clamped by maxCoverAspectMultiplier: 2.
      final int? clampedPanorama = forkResolveProxyRequestWidth(
        layoutWidth: 150,
        layoutHeight: 150,
        devicePixelRatio: 2,
        sourceWidth: 10000,
        sourceHeight: 1000,
        cover: true,
        maxCoverAspectMultiplier: 2,
      );
      expect(clampedPanorama, 600);
    });
  });

  group('buildForkSizedThumbnailUrl & endpoint trust scoping', () {
    test(
      'emits single-width WebP high quality with no height in both HDR modes',
      () {
        const String src =
            '$mediaBase/attachments/1/2/camera.heic?ex=abc&is=def&hm=123';
        for (final HdrDisplayMode mode in HdrDisplayMode.values) {
          final String fallback = buildHdrAwareImageUrl(
            url: src,
            mode: mode,
            contentType: 'image/heic',
          );
          final String thumb = buildForkSizedThumbnailUrl(
            url: src,
            fallbackUrl: fallback,
            layoutWidth: 300,
            layoutHeight: 225,
            devicePixelRatio: 3,
            sourceWidth: 4032,
            sourceHeight: 3024,
            contentType: 'image/heic',
            mediaEndpoint: mediaBase,
          );
          final Uri uri = Uri.parse(thumb);
          expect(uri.queryParameters['format'], 'webp', reason: '$mode');
          expect(uri.queryParameters['quality'], 'high', reason: '$mode');
          expect(uri.queryParameters['width'], '1024', reason: '$mode');
          expect(uri.queryParameters['height'], isNull, reason: '$mode');
          expect(uri.queryParameters['ex'], 'abc');
          expect(uri.queryParameters['hm'], '123');
        }
      },
    );

    test(
      'replaces existing transform params with set-semantics without duplicates',
      () {
        const String src =
            '$mediaBase/attachments/1/2/p.png?width=400&height=300&format=png&fmt=jpeg&quality=low&tag=a&tag=b';
        final String thumb = buildForkSizedThumbnailUrl(
          url: src,
          fallbackUrl: src,
          layoutWidth: 160,
          layoutHeight: 120,
          devicePixelRatio: 2,
          sourceWidth: 4000,
          sourceHeight: 3000,
          mediaEndpoint: mediaBase,
        );
        final Uri uri = Uri.parse(thumb);
        expect(uri.queryParametersAll['width'], <String>['320']);
        expect(uri.queryParametersAll['height'], isNull);
        expect(uri.queryParametersAll['format'], <String>['webp']);
        expect(uri.queryParametersAll['fmt'], isNull);
        expect(uri.queryParametersAll['quality'], <String>['high']);
        expect(uri.queryParametersAll['tag'], <String>['a', 'b']);
      },
    );

    test(
      'returns direct external URLs strictly verbatim in both HDR modes',
      () {
        const String externalUrl =
            'https://cdn.thirdparty.example/photo.jpg?v=1';
        for (final HdrDisplayMode mode in HdrDisplayMode.values) {
          final String fallback = buildHdrAwareImageUrl(
            url: externalUrl,
            mode: mode,
            contentType: 'image/jpeg',
          );
          final String result = buildForkSizedThumbnailUrl(
            url: externalUrl,
            fallbackUrl: fallback,
            layoutWidth: 200,
            layoutHeight: 150,
            devicePixelRatio: 3,
            sourceWidth: 4000,
            sourceHeight: 3000,
            mediaEndpoint: mediaBase,
          );
          expect(result, externalUrl, reason: '$mode');
        }
      },
    );

    test('returns SVG URLs verbatim and never transforms them', () {
      const String svgUrl = '$mediaBase/attachments/1/2/diagram.svg';
      expect(
        buildForkSizedThumbnailUrl(
          url: svgUrl,
          fallbackUrl: svgUrl,
          layoutWidth: 200,
          layoutHeight: 200,
          devicePixelRatio: 2,
          sourceWidth: 4000,
          sourceHeight: 4000,
          contentType: 'image/svg+xml',
          filename: 'diagram.svg',
          mediaEndpoint: mediaBase,
        ),
        svgUrl,
      );
      expect(
        forkIsPreloadableMediaUrl(
          svgUrl,
          mediaEndpoint: mediaBase,
          contentType: 'image/svg+xml',
        ),
        isFalse,
      );
    });

    test('preserves per-call-site fallbackUrl when unresized or animated', () {
      const String src = '$mediaBase/attachments/1/2/small.avif';
      final String hdrFallback = buildHdrAwareImageUrl(
        url: src,
        mode: HdrDisplayMode.standard,
        contentType: 'image/avif',
      );
      // Small image -> no downscale -> returns fallbackUrl unchanged.
      expect(
        buildForkSizedThumbnailUrl(
          url: src,
          fallbackUrl: hdrFallback,
          layoutWidth: 300,
          layoutHeight: 200,
          devicePixelRatio: 3,
          sourceWidth: 200,
          sourceHeight: 150,
          contentType: 'image/avif',
          mediaEndpoint: mediaBase,
        ),
        hdrFallback,
      );
      // Animated image -> returns fallbackUrl unchanged.
      expect(
        buildForkSizedThumbnailUrl(
          url: '$mediaBase/attachments/1/2/clip.gif?animated=true',
          fallbackUrl: 'https://custom-fallback.example/clip',
          layoutWidth: 100,
          layoutHeight: 100,
          devicePixelRatio: 2,
          sourceWidth: 4000,
          sourceHeight: 4000,
          mediaEndpoint: mediaBase,
        ),
        'https://custom-fallback.example/clip',
      );
    });

    test('rejects API attachment URLs in forkIsPreloadableMediaUrl even when '
        'mediaEndpoint shares root host', () {
      const String apiBase = 'https://shared.tyne.test/api/v1';
      AttachmentRequestAuth.update(
        token: 'test-token',
        baseUrl: apiBase,
        mintToken: null,
      );
      addTearDown(
        () => AttachmentRequestAuth.update(
          token: null,
          baseUrl: null,
          mintToken: null,
        ),
      );
      const String rootOrigin = 'https://shared.tyne.test';
      const String apiAttachmentUrl =
          '$apiBase/channels/100/attachments/200/photo.png';
      expect(
        forkIsTransformableMediaUrl(
          apiAttachmentUrl,
          mediaEndpoint: rootOrigin,
        ),
        isTrue,
      );
      expect(
        forkIsPreloadableMediaUrl(apiAttachmentUrl, mediaEndpoint: rootOrigin),
        isFalse,
      );
      // API attachment transform width is capped at 8192.
      final String apiThumb = buildForkSizedThumbnailUrl(
        url: apiAttachmentUrl,
        fallbackUrl: apiAttachmentUrl,
        layoutWidth: 12000,
        layoutHeight: 12000,
        devicePixelRatio: 1,
        sourceWidth: 16000,
        sourceHeight: 16000,
        mediaEndpoint: rootOrigin,
      );
      expect(Uri.parse(apiThumb).queryParameters['width'], '8192');
    });
  });

  group('audio cover sizing scoping', () {
    tearDown(ChatAttachmentAudioController.resetForTest);

    Widget buildAudioCard(Attachment attachment) {
      final colorTheme = buildDarkColorTheme();
      return MaterialApp(
        locale: kTestLocale,
        localizationsDelegates: fluxerLocalizationsDelegates,
        supportedLocales: FluxerLocalizations.supportedLocales,
        theme: buildFluxerTheme(
          colorTheme: colorTheme,
          textTheme: FluxerTextTheme.fromColors(colorTheme),
          layoutTheme: FluxerLayoutTheme.scaled(),
        ),
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: ForkAttachmentAudioCard(
              controller: ChatAttachmentAudioController(
                sourceUrl: attachment.proxyUrl ?? attachment.url,
                attachment: attachment,
                title: () => attachment.filename,
              ),
              attachment: attachment,
              onTogglePlayback: () {},
              onDownload: () {},
            ),
          ),
        ),
      );
    }

    testWidgets(
      'snaps cover width on media proxy URLs and omits width on API attachment URLs',
      (WidgetTester tester) async {
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);

        const Attachment mediaAudio = Attachment(
          id: 'a1',
          url: 'https://cdn.example/attachments/1/2/song.flac',
          proxyUrl:
              'https://media.example/attachments/1/2/song.flac?ex=1&hm=abc',
          filename: 'song.flac',
          contentType: 'audio/flac',
          flags: kForkAttachmentFlagHasCover,
        );
        await tester.pumpWidget(buildAudioCard(mediaAudio));
        final ChatNetworkImage mediaCover = tester.widget<ChatNetworkImage>(
          find.byType(ChatNetworkImage),
        );
        final Uri mediaUri = Uri.parse(mediaCover.imageUrl);
        // 76 * 3 = 228 -> snaps to ladder rung 240.
        expect(mediaUri.queryParameters['width'], '240');
        expect(mediaUri.queryParameters['cover'], '1');

        const String apiBase = 'https://api.tyne.test/api/v1';
        AttachmentRequestAuth.update(
          token: 'test-token',
          baseUrl: apiBase,
          mintToken: null,
        );
        addTearDown(
          () => AttachmentRequestAuth.update(
            token: null,
            baseUrl: null,
            mintToken: null,
          ),
        );
        const Attachment apiAudio = Attachment(
          id: 'a2',
          url: '$apiBase/channels/100/attachments/200/song.flac',
          proxyUrl: '$apiBase/channels/100/attachments/200/song.flac',
          filename: 'song.flac',
          contentType: 'audio/flac',
          flags: kForkAttachmentFlagHasCover,
        );
        await tester.pumpWidget(buildAudioCard(apiAudio));
        final ChatNetworkImage apiCover = tester.widget<ChatNetworkImage>(
          find.byType(ChatNetworkImage),
        );
        final Uri apiUri = Uri.parse(apiCover.imageUrl);
        expect(apiUri.queryParameters['width'], isNull);
        expect(apiUri.queryParameters['cover'], '1');
      },
    );
  });
}
