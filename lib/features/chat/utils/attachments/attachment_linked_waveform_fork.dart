// Fork (tyne-chat/tyne#873): the waveform of a link to an audio attachment.
//
// An attachment carries its waveform; a pasted link to one becomes an embed, which has no waveform
// field. The server flags the embed's audio `HAS_WAVEFORM` (the phone shows an audio embed as an
// attachment with the embed's flags, `attachmentFromEmbedAudio`), and the media proxy serves the
// stored waveform, raw bytes, from the link's own URL with `waveform=1`.
//
// Requests: one per linked file while the app runs, shared by every card showing it (links to the
// same file differ only in their signature, so the key is the URL without its query). A request
// that fails (404, 429, offline) is not made again until the app restarts. They go to the media
// proxy, not the API, so they do not count towards the API's per-user rate limit.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:fluxer_app/core/api/attachment_request_auth.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/utils/attachments/attachment_display_utils.dart';

/// The flag the server sets on a link embed's audio whose waveform can be loaded (the server's
/// `ForkMessageAttachmentFlags.HAS_WAVEFORM`, next to `kForkAttachmentFlagHasCover`).
const int kForkAttachmentFlagHasWaveform = 1 << 20;

/// The query parameter that makes the media proxy serve an attachment's waveform.
const String kForkAttachmentWaveformParameter = 'waveform';

/// A waveform is at most 256 bytes; anything much larger is not one.
const int _kMaxWaveformBytes = 4096;

/// Whether [attachment] is a link whose waveform the server can serve and it has none of its own.
bool forkAttachmentHasLinkedWaveform(Attachment attachment) {
  final String? own = attachment.waveform;
  return (own == null || own.isEmpty) &&
      (attachment.flags & kForkAttachmentFlagHasWaveform) != 0;
}

/// Loads linked waveforms, each once (see the file's comment).
class ForkLinkedWaveformLoader {
  ForkLinkedWaveformLoader(this._dio);

  final Dio _dio;
  final Map<String, Future<String?>> _loaded = <String, Future<String?>>{};

  /// The waveform of the file at [attachmentUrl], as base64 like an attachment's, or null.
  Future<String?> load(String attachmentUrl) {
    final Uri? url = Uri.tryParse(attachmentUrl);
    if (url == null || !url.hasScheme) {
      return Future<String?>.value();
    }
    final String key = url.replace(query: '').toString();
    return _loaded.putIfAbsent(key, () => _fetch(url));
  }

  Future<String?> _fetch(Uri url) async {
    final Map<String, String> query = Map<String, String>.from(
      url.queryParameters,
    )..[kForkAttachmentWaveformParameter] = '1';
    try {
      final Response<List<int>> response = await _dio.get<List<int>>(
        url.replace(queryParameters: query).toString(),
        options: Options(responseType: ResponseType.bytes),
      );
      final List<int>? bytes = response.data;
      if (response.statusCode != 200 ||
          bytes == null ||
          bytes.isEmpty ||
          bytes.length > _kMaxWaveformBytes) {
        return null;
      }
      return base64Encode(Uint8List.fromList(bytes));
    } on Object {
      return null;
    }
  }
}

final Provider<ForkLinkedWaveformLoader> forkLinkedWaveformLoaderProvider =
    Provider<ForkLinkedWaveformLoader>(
      (Ref ref) => ForkLinkedWaveformLoader(
        Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
          ),
        )..interceptors.add(AttachmentAuthInterceptor()),
      ),
    );

/// The waveform of a linked attachment, by its effective URL (`attachmentEffectiveUrl`).
final FutureProviderFamily<String?, String> forkLinkedWaveformProvider =
    FutureProvider.autoDispose.family<String?, String>(
      (Ref ref, String attachmentUrl) =>
          ref.watch(forkLinkedWaveformLoaderProvider).load(attachmentUrl),
    );

/// The URL a linked waveform is loaded for.
String forkLinkedWaveformKey(Attachment attachment) =>
    attachmentEffectiveUrl(attachment);
