// Fork: a saved audio file in the Media tab shows its cover, or its waveform, loading each at most
// once per file and nothing off screen (tyne-chat/tyne#879; the network rules in the server's
// AGENTS.md).

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/features/chat/domain/favorite_meme.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/pickers/saved_audio_preview_fork.dart';
import 'package:fluxer_app/features/chat/utils/attachments/attachment_linked_waveform_fork.dart';
import 'package:fluxer_app/material_ui.dart';

const String _url =
    'https://media.example/attachments/7/8/Chime.wav?ex=1&is=2&hm=abc';

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.answer);

  final ResponseBody Function() answer;
  final List<Uri> requested = <Uri>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requested.add(options.uri);
    return answer();
  }

  @override
  void close({bool force = false}) {}
}

FavoriteMeme _meme({String url = _url, String filename = 'Chime.wav'}) =>
    FavoriteMeme(
      id: '1',
      userId: '7',
      name: 'Chime',
      altText: null,
      tags: const [],
      attachmentId: '8',
      filename: filename,
      contentType: 'audio/wav',
      contentHash: null,
      size: 1,
      width: null,
      height: null,
      duration: 3,
      isGifv: false,
      url: url,
      klipySlug: null,
      tenorSlugId: null,
    );

final Map<_RecordingAdapter, ForkLinkedWaveformLoader> _loaders =
    <_RecordingAdapter, ForkLinkedWaveformLoader>{};

/// The app around [child], with one waveform loader per adapter, as the app has one for its life.
Widget _app(_RecordingAdapter adapter, Widget child) {
  final colorTheme = buildDarkColorTheme();
  final ForkLinkedWaveformLoader loader = _loaders.putIfAbsent(
    adapter,
    () => ForkLinkedWaveformLoader(Dio()..httpClientAdapter = adapter),
  );
  return ProviderScope(
    overrides: [forkLinkedWaveformLoaderProvider.overrideWithValue(loader)],
    child: MaterialApp(
      theme: buildFluxerTheme(
        colorTheme: colorTheme,
        textTheme: FluxerTextTheme.fromColors(colorTheme),
        layoutTheme: FluxerLayoutTheme.scaled(),
      ),
      home: Scaffold(
        body: Center(child: SizedBox(width: 180, height: 300, child: child)),
      ),
    ),
  );
}

void main() {
  tearDown(forkForgetMissingSavedAudioCovers);

  test(
    'asks for the cover from the saved file, resized, keeping its signature',
    () {
      final Uri cover = Uri.parse(forkSavedAudioCoverUrl(_url));
      expect(cover.path, '/attachments/7/8/Chime.wav');
      expect(cover.queryParameters['cover'], '1');
      expect(cover.queryParameters['format'], 'webp');
      expect(cover.queryParameters['hm'], 'abc');
      expect(forkSavedAudioCoverUrl(''), isEmpty);
    },
  );

  test('shows the format from the file name, or else the content type', () {
    expect(forkSavedAudioFormat(_meme()), 'WAV');
    expect(forkSavedAudioFormat(_meme(filename: 'recording')), 'WAV');
  });

  test('remembers a missing cover for the file, whatever its signature', () {
    expect(forkSavedAudioCoverMissing(_url), isFalse);
    forkMarkSavedAudioCoverMissing(_url);
    expect(
      forkSavedAudioCoverMissing(_url.replaceFirst('hm=abc', 'hm=def')),
      isTrue,
    );
  });

  testWidgets('fits the shortest tile the picker makes', (tester) async {
    forkMarkSavedAudioCoverMissing(_url);
    final adapter = _RecordingAdapter(
      () => ResponseBody.fromBytes(<int>[0, 128, 255], 200),
    );
    final colorTheme = buildDarkColorTheme();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          forkLinkedWaveformLoaderProvider.overrideWithValue(
            ForkLinkedWaveformLoader(Dio()..httpClientAdapter = adapter),
          ),
        ],
        child: MaterialApp(
          theme: buildFluxerTheme(
            colorTheme: colorTheme,
            textTheme: FluxerTextTheme.fromColors(colorTheme),
            layoutTheme: FluxerLayoutTheme.scaled(),
          ),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 110,
                height: 128,
                child: ForkSavedAudioPreview(meme: _meme(), isVisible: true),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('loads nothing off screen', (tester) async {
    final adapter = _RecordingAdapter(
      () => ResponseBody.fromBytes(<int>[0, 128, 255], 200),
    );
    await tester.pumpWidget(
      _app(adapter, ForkSavedAudioPreview(meme: _meme(), isVisible: false)),
    );
    await tester.pump();

    expect(adapter.requested, isEmpty);
    expect(find.byType(Image), findsNothing);
    expect(find.text('Chime.wav'), findsOneWidget);
  });

  testWidgets(
    'without a cover shows the waveform, asking once per file however often it is built',
    (tester) async {
      forkMarkSavedAudioCoverMissing(_url);
      final adapter = _RecordingAdapter(
        () => ResponseBody.fromBytes(<int>[0, 128, 255, 128], 200),
      );
      final Widget tiles = Column(
        children: [
          Expanded(
            child: ForkSavedAudioPreview(meme: _meme(), isVisible: true),
          ),
          Expanded(
            child: ForkSavedAudioPreview(
              meme: _meme(url: _url.replaceFirst('hm=abc', 'hm=def')),
              isVisible: true,
            ),
          ),
        ],
      );
      await tester.pumpWidget(_app(adapter, tiles));
      await tester.pumpAndSettle();
      await tester.pumpWidget(_app(adapter, tiles));
      await tester.pumpAndSettle();

      expect(adapter.requested, hasLength(1));
      expect(adapter.requested.single.queryParameters['waveform'], '1');
      expect(find.byType(FractionallySizedBox), findsWidgets);
      expect(find.text('WAV'), findsNWidgets(2));
    },
  );

  testWidgets(
    'shows a flat line when the waveform cannot be loaded, without asking again',
    (tester) async {
      forkMarkSavedAudioCoverMissing(_url);
      final adapter = _RecordingAdapter(() => ResponseBody.fromString('', 429));
      final Widget tile = ForkSavedAudioPreview(meme: _meme(), isVisible: true);
      await tester.pumpWidget(_app(adapter, tile));
      await tester.pumpAndSettle();
      await tester.pumpWidget(_app(adapter, tile));
      await tester.pumpAndSettle();

      expect(adapter.requested, hasLength(1));
      expect(find.byType(FractionallySizedBox), findsNothing);
    },
  );
}
