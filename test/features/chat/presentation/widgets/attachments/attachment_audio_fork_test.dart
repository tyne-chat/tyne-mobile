// Fork: tests of the audio card with cover art and a waveform (tyne-chat/tyne#873).
//
// Upstream's `attachment_audio_test.dart` runs against the same card (the fork's replaces upstream's
// card body); these test what the fork adds.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/audio/chat_attachment/chat_attachment_audio_controller.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/attachments/attachment_audio_card_fork.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/media/chat_network_image.dart';
import 'package:fluxer_app/features/chat/utils/attachments/attachment_cover_fork.dart';
import 'package:fluxer_app/material_ui.dart';

import '../../../../../helpers/test_l10n.dart';

const String _signedUrl =
    'https://media.example/attachments/1/2/Spell.wav?ex=1&is=2&hm=abc';

Attachment _attachment({
  String filename = 'Spell.wav',
  int flags = 0,
  String? waveform,
}) {
  return Attachment(
    id: 'attachment-audio',
    url: 'https://cdn.example/attachments/1/2/$filename',
    proxyUrl: _signedUrl,
    filename: filename,
    contentType: 'audio/wav',
    size: 1024,
    flags: flags,
    waveform: waveform,
  );
}

Widget _card(
  Attachment attachment, {
  VoidCallback? onTogglePlayback,
  double width = 360,
}) {
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
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: width,
          child: ForkAttachmentAudioCard(
            controller: ChatAttachmentAudioController(
              sourceUrl: attachment.proxyUrl ?? attachment.url,
              attachment: attachment,
              title: () => attachment.filename,
            ),
            attachment: attachment,
            onTogglePlayback: onTogglePlayback ?? () {},
            onDownload: () {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  tearDown(ChatAttachmentAudioController.resetForTest);

  testWidgets('shows the cover only for an attachment the server flagged', (
    tester,
  ) async {
    await tester.pumpWidget(
      _card(_attachment(flags: kForkAttachmentFlagHasCover)),
    );
    final ChatNetworkImage cover = tester.widget<ChatNetworkImage>(
      find.byType(ChatNetworkImage),
    );
    final Uri coverUrl = Uri.parse(cover.imageUrl);
    expect(coverUrl.path, '/attachments/1/2/Spell.wav');
    expect(coverUrl.queryParameters['cover'], '1');
    expect(coverUrl.queryParameters['format'], 'webp');
    expect(coverUrl.queryParameters['hm'], 'abc');

    await tester.pumpWidget(_card(_attachment()));
    expect(find.byType(ChatNetworkImage), findsNothing);
  });

  testWidgets('a tap anywhere on the title row plays or pauses', (
    tester,
  ) async {
    int toggles = 0;
    await tester.pumpWidget(
      _card(_attachment(), onTogglePlayback: () => toggles++),
    );
    await tester.tap(find.textContaining('Spell'));
    await tester.pump();
    expect(toggles, 1);
    final Rect row = tester.getRect(find.textContaining('Spell'));
    await tester.tapAt(Offset(row.right - 2, row.center.dy));
    await tester.pump();
    expect(toggles, 2);
  });

  testWidgets('a long name is cut, and its extension still shows', (
    tester,
  ) async {
    const String long =
        'Nightmare_Magic_Cast_Subjugate_Ominous_With_A_Much_Longer_Name_Still_Going';
    await tester.pumpWidget(
      _card(_attachment(filename: '$long.wav'), width: 260),
    );
    final Finder name = find.byWidgetPredicate(
      (Widget widget) =>
          widget is Text &&
          (widget.textSpan?.toPlainText() ?? '').endsWith('.wav'),
    );
    final String shown = tester.widget<Text>(name).textSpan!.toPlainText();
    expect(shown, endsWith('….wav'));
    expect(shown.length, lessThan(long.length));
  });

  testWidgets('draws the waveform, or a plain bar without one', (tester) async {
    final String waveform = base64Encode(<int>[0, 64, 128, 255, 128, 64]);
    await tester.pumpWidget(_card(_attachment(waveform: waveform)));
    expect(find.byType(LinearProgressIndicator), findsNothing);

    await tester.pumpWidget(_card(_attachment()));
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  group('forkTruncateAudioStem', () {
    bool fitsIn(int characters, String text) => text.length <= characters;

    test('keeps a name that fits whole', () {
      expect(
        forkTruncateAudioStem('Spell', '.wav', (t) => fitsIn(40, t)),
        'Spell',
      );
    });

    test(
      'cuts the longest start that fits with the ellipsis and extension',
      () {
        expect(
          forkTruncateAudioStem(
            'Nightmare_Magic_Cast',
            '.wav',
            (t) => fitsIn(15, t),
          ),
          'Nightmare_…',
        );
      },
    );
  });

  group('forkResampleWaveform', () {
    test('averages the values each bar covers', () {
      expect(forkResampleWaveform(<int>[0, 100, 200, 255], 2), <int>[50, 228]);
    });

    test('stretches a short waveform over more bars', () {
      expect(forkResampleWaveform(<int>[255, 0], 4), <int>[255, 255, 0, 0]);
    });

    test('draws nothing from nothing', () {
      expect(forkResampleWaveform(<int>[], 8), isEmpty);
    });
  });

  group('the lock screen artwork', () {
    test('is the cover, resized, for a flagged attachment', () {
      final Uri? art = forkAttachmentAudioArtUri(
        _attachment(flags: kForkAttachmentFlagHasCover),
      );
      expect(art, isNotNull);
      expect(art!.queryParameters['cover'], '1');
      expect(art.queryParameters['width'], '512');
    });

    test('stays the app icon otherwise', () {
      expect(forkAttachmentAudioArtUri(_attachment()), isNull);
    });
  });
}
