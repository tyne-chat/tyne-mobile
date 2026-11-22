// Fork: the waveform of a link to an audio attachment, loaded once per linked file and never asked
// again after a failure (tyne-chat/tyne#873; the network rules in the server's AGENTS.md).

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/utils/attachments/attachment_linked_waveform_fork.dart';

const String _link =
    'https://media.example/attachments/1/2/Spell.wav?ex=1&is=2&hm=abc';
const String _otherSignature =
    'https://media.example/attachments/1/2/Spell.wav?ex=3&is=4&hm=def';

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.answer);

  final Future<ResponseBody> Function() answer;
  final List<Uri> requested = <Uri>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requested.add(options.uri);
    return answer();
  }

  @override
  void close({bool force = false}) {}
}

ForkLinkedWaveformLoader _loader(_RecordingAdapter adapter) {
  return ForkLinkedWaveformLoader(Dio()..httpClientAdapter = adapter);
}

Attachment _attachment({int flags = 0, String? waveform}) {
  return Attachment(
    id: '0-audio',
    url: _link,
    proxyUrl: _link,
    filename: 'Spell.wav',
    contentType: 'audio/wav',
    size: 0,
    flags: flags,
    waveform: waveform,
  );
}

void main() {
  test('loads a linked file once, with waveform=1, as base64', () async {
    final _RecordingAdapter adapter = _RecordingAdapter(
      () async => ResponseBody.fromBytes(<int>[0, 64, 255, 128], 200),
    );
    final ForkLinkedWaveformLoader loader = _loader(adapter);

    final List<String?> loaded = await Future.wait(<Future<String?>>[
      loader.load(_link),
      loader.load(_otherSignature),
    ]);
    final String? later = await loader.load(_link);

    expect(loaded, <String?>['AED/gA==', 'AED/gA==']);
    expect(later, 'AED/gA==');
    expect(adapter.requested, hasLength(1));
    expect(adapter.requested.single.path, '/attachments/1/2/Spell.wav');
    expect(adapter.requested.single.queryParameters['waveform'], '1');
    expect(adapter.requested.single.queryParameters['hm'], 'abc');
  });

  test('does not ask again after the file has none (404)', () async {
    final _RecordingAdapter adapter = _RecordingAdapter(
      () async => ResponseBody.fromString('Not Found', 404),
    );
    final ForkLinkedWaveformLoader loader = _loader(adapter);

    expect(await loader.load(_link), isNull);
    expect(await loader.load(_link), isNull);
    expect(adapter.requested, hasLength(1));
  });

  test('does not ask again after the request fails (429, offline)', () async {
    final _RecordingAdapter limited = _RecordingAdapter(
      () async => ResponseBody.fromString('', 429),
    );
    final ForkLinkedWaveformLoader limitedLoader = _loader(limited);
    expect(await limitedLoader.load(_link), isNull);
    expect(await limitedLoader.load(_otherSignature), isNull);
    expect(limited.requested, hasLength(1));

    final _RecordingAdapter offline = _RecordingAdapter(
      () async => throw DioException.connectionError(
        requestOptions: RequestOptions(path: _link),
        reason: 'offline',
      ),
    );
    final ForkLinkedWaveformLoader offlineLoader = _loader(offline);
    expect(await offlineLoader.load(_link), isNull);
    expect(await offlineLoader.load(_link), isNull);
    expect(offline.requested, hasLength(1));
  });

  test('refuses an answer too large to be a waveform', () async {
    final _RecordingAdapter adapter = _RecordingAdapter(
      () async => ResponseBody.fromBytes(List<int>.filled(5000, 1), 200),
    );
    expect(await _loader(adapter).load(_link), isNull);
  });

  test('is loaded only for a flagged link with no waveform of its own', () {
    expect(
      forkAttachmentHasLinkedWaveform(
        _attachment(flags: kForkAttachmentFlagHasWaveform),
      ),
      isTrue,
    );
    expect(
      forkAttachmentHasLinkedWaveform(
        _attachment(flags: kForkAttachmentFlagHasWaveform, waveform: 'AAEC'),
      ),
      isFalse,
    );
    expect(forkAttachmentHasLinkedWaveform(_attachment()), isFalse);
  });
}
