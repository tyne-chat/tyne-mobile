import 'dart:io';
import 'dart:isolate';

import 'package:cryptography/dart.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:fluxer_app/core/updater/app_update_info.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class AppUpdateService {
  AppUpdateService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  // Test builds can point the updater at another repository's releases
  // (`--dart-define=FORK_UPDATE_REPO=owner/name`) to try an update end to end
  // without publishing to users. Published builds leave it unset.
  // ignore: do_not_use_environment -- compile-time build config
  static const String _kGitHubRepo = String.fromEnvironment(
    'FORK_UPDATE_REPO',
    defaultValue: 'tyne-chat/tyne-mobile',
  );
  static const String _kLatestReleaseUrl =
      'https://api.github.com/repos/$_kGitHubRepo/releases/latest';

  static const String _kDownloadHost = 'github.com';
  static const String _kDownloadPathPrefix =
      '/$_kGitHubRepo/releases/download/';
  static const String _kDownloadDirName = 'updates';
  static const String _kDownloadFileName = 'tyne-update.apk';
  static final RegExp _kSha256Digest = RegExp(r'^sha256:([0-9a-f]{64})$');

  static const MethodChannel _kInstallChannel = MethodChannel(
    'fluxer_app/app_install',
  );

  static bool isSupportedPlatform() => platformOverride ?? Platform.isAndroid;

  @visibleForTesting
  static bool? platformOverride;

  Future<AppUpdateInfo?> checkForUpdate() async {
    if (!isSupportedPlatform()) {
      return null;
    }

    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final Response<dynamic> response = await _dio.get<dynamic>(
        _kLatestReleaseUrl,
        options: Options(
          headers: const <String, String>{
            'User-Agent': 'TyneApp',
            'Accept': 'application/vnd.github.v3+json',
          },
          responseType: ResponseType.json,
        ),
      );

      final dynamic responseData = response.data;
      if (responseData is! Map<String, dynamic>) {
        return null;
      }
      final Map<String, dynamic> data = responseData;

      final String tagName = (data['tag_name'] as String? ?? '').trim();
      final String title = (data['name'] as String? ?? tagName).trim();
      final String body = (data['body'] as String? ?? '').trim();
      final String? publishedAtStr = data['published_at'] as String?;
      final DateTime? publishedAt = publishedAtStr != null
          ? DateTime.tryParse(publishedAtStr)
          : null;

      final List<dynamic> assets =
          data['assets'] as List<dynamic>? ?? <dynamic>[];
      Map<String, dynamic>? apkAsset;
      for (final dynamic item in assets) {
        if (item is Map<String, dynamic>) {
          final String name = item['name'] as String? ?? '';
          if (name.endsWith('.apk')) {
            apkAsset = item;
            break;
          }
        }
      }

      if (apkAsset == null || tagName.isEmpty) {
        return null;
      }

      final String downloadUrl =
          apkAsset['browser_download_url'] as String? ?? '';
      final String fileName = apkAsset['name'] as String? ?? 'tyne.apk';
      final int fileSize = (apkAsset['size'] as num?)?.toInt() ?? 0;
      final String? sha256 = _kSha256Digest
          .firstMatch((apkAsset['digest'] as String? ?? '').toLowerCase())
          ?.group(1);

      // Without a trusted URL, a size and a digest the download cannot be
      // verified, so the release is not offered at all.
      if (!isTrustedDownloadUrl(downloadUrl) ||
          fileSize <= 0 ||
          sha256 == null) {
        if (kDebugMode) {
          debugPrint(
            '[AppUpdateService] ignoring $tagName: unverifiable asset '
            '(url: $downloadUrl, size: $fileSize, digest: ${apkAsset['digest']})',
          );
        }
        return null;
      }

      final (String latestVersion, int? latestBuild) = _parseTagVersion(
        tagName,
      );
      final int? currentBuild = int.tryParse(packageInfo.buildNumber);

      final bool newer = isNewerVersion(
        currentVersion: packageInfo.version,
        latestVersion: latestVersion,
        currentBuild: currentBuild,
        latestBuild: latestBuild,
      );

      if (!newer) {
        return null;
      }

      return AppUpdateInfo(
        tagName: tagName,
        version: latestVersion,
        buildNumber: latestBuild,
        title: title,
        releaseNotes: body,
        downloadUrl: downloadUrl,
        fileName: fileName,
        fileSizeBytes: fileSize,
        sha256: sha256,
        publishedAt: publishedAt,
      );
    } on Object catch (e, st) {
      if (kDebugMode) {
        debugPrint('[AppUpdateService] check for update error: $e\n$st');
      }
      return null;
    }
  }

  Future<File?> downloadUpdate(
    AppUpdateInfo info, {
    void Function(double progress, int received, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    File? partFile;
    try {
      if (!isTrustedDownloadUrl(info.downloadUrl) || info.fileSizeBytes <= 0) {
        return null;
      }

      // Fixed name: the asset name comes from the network and must not be
      // used as a path component. The folder is the only one the app's
      // FileProvider exposes (android/app/src/main/res/xml/file_paths.xml).
      final Directory tempDir = await getTemporaryDirectory();
      final Directory updatesDir = Directory(
        '${tempDir.path}/$_kDownloadDirName',
      )..createSync(recursive: true);
      final File targetFile = File('${updatesDir.path}/$_kDownloadFileName');
      final File part = partFile = File('${targetFile.path}.part');
      for (final File stale in <File>[targetFile, part]) {
        if (stale.existsSync()) {
          stale.deleteSync();
        }
      }

      final CancelToken token = cancelToken ?? CancelToken();
      await _dio.download(
        info.downloadUrl,
        part.path,
        onReceiveProgress: (int received, int total) {
          if (received > info.fileSizeBytes) {
            token.cancel('update is larger than the release says');
            return;
          }
          if (onProgress != null && total > 0) {
            final double percent = received / total;
            onProgress(percent, received, total);
          }
        },
        cancelToken: token,
        options: Options(
          headers: const <String, String>{'User-Agent': 'TyneApp'},
        ),
      );

      final int length = part.lengthSync();
      final String? actualSha256 = length == info.fileSizeBytes
          ? await _sha256OfFileInIsolate(part.path)
          : null;
      if (actualSha256 != info.sha256.toLowerCase()) {
        if (kDebugMode) {
          debugPrint(
            '[AppUpdateService] discarding download: got $length bytes, '
            'sha256 $actualSha256; expected ${info.fileSizeBytes} bytes, '
            'sha256 ${info.sha256}',
          );
        }
        part.deleteSync();
        return null;
      }

      return part.renameSync(targetFile.path);
    } on Object catch (e, st) {
      if (kDebugMode) {
        debugPrint('[AppUpdateService] download update error: $e\n$st');
      }
      try {
        if (partFile != null && partFile.existsSync()) {
          partFile.deleteSync();
        }
      } on FileSystemException catch (_) {}
      return null;
    }
  }

  /// Whether [url] is an https release asset of this app's GitHub repository.
  @visibleForTesting
  static bool isTrustedDownloadUrl(String url) {
    final Uri? uri = Uri.tryParse(url);
    return uri != null &&
        uri.isScheme('https') &&
        uri.host == _kDownloadHost &&
        uri.userInfo.isEmpty &&
        uri.port == 443 &&
        uri.path.startsWith(_kDownloadPathPrefix);
  }

  // A static with only [path] in scope, so the closure sent to the isolate
  // cannot capture anything unsendable.
  static Future<String> _sha256OfFileInIsolate(String path) =>
      Isolate.run(() => _sha256OfFile(path));

  static String _sha256OfFile(String path) {
    final DartHashSink sink = const DartSha256().newHashSink();
    final RandomAccessFile file = File(path).openSync();
    try {
      final Uint8List buffer = Uint8List(1024 * 1024);
      int read;
      while ((read = file.readIntoSync(buffer)) > 0) {
        sink.addSlice(buffer, 0, read, false);
      }
    } finally {
      file.closeSync();
    }
    sink.close();
    return sink
        .hashSync()
        .bytes
        .map((int b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  Future<bool> canRequestPackageInstalls() async {
    if (!isSupportedPlatform()) {
      return false;
    }
    try {
      final bool? result = await _kInstallChannel.invokeMethod<bool>(
        'canRequestPackageInstalls',
      );
      return result ?? false;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('[AppUpdateService] canRequestPackageInstalls error: $e');
      }
      return false;
    }
  }

  Future<bool> openInstallPermissionSettings() async {
    if (!isSupportedPlatform()) {
      return false;
    }
    try {
      final bool? result = await _kInstallChannel.invokeMethod<bool>(
        'openInstallPermissionSettings',
      );
      return result ?? false;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[AppUpdateService] openInstallPermissionSettings error: $e',
        );
      }
      return false;
    }
  }

  Future<bool> installUpdate(String filePath) async {
    if (!isSupportedPlatform()) {
      return false;
    }
    try {
      final bool? result = await _kInstallChannel.invokeMethod<bool>(
        'installPackage',
        <String, dynamic>{'filePath': filePath},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('[AppUpdateService] installUpdate error: $e');
      }
      return false;
    }
  }

  static String cleanVersion(String v) {
    String clean = v.trim();
    if (clean.startsWith('v') || clean.startsWith('V')) {
      clean = clean.substring(1);
    }
    if (clean.contains('+')) {
      clean = clean.split('+')[0];
    }
    if (clean.contains('-')) {
      clean = clean.split('-')[0];
    }
    return clean;
  }

  static (String version, int? build) _parseTagVersion(String tag) {
    String clean = tag.trim();
    if (clean.startsWith('v') || clean.startsWith('V')) {
      clean = clean.substring(1);
    }
    int? build;
    if (clean.contains('+')) {
      final List<String> parts = clean.split('+');
      clean = parts[0];
      build = int.tryParse(parts[1]);
    }
    if (clean.contains('-')) {
      clean = clean.split('-')[0];
    }
    return (clean, build);
  }

  static bool isNewerVersion({
    required String currentVersion,
    required String latestVersion,
    int? currentBuild,
    int? latestBuild,
  }) {
    final String cleanCur = cleanVersion(currentVersion);
    final String cleanLat = cleanVersion(latestVersion);

    final List<int> curParts = cleanCur
        .split('.')
        .map((String p) => int.tryParse(p) ?? 0)
        .toList();
    final List<int> latParts = cleanLat
        .split('.')
        .map((String p) => int.tryParse(p) ?? 0)
        .toList();

    while (curParts.length < 3) {
      curParts.add(0);
    }
    while (latParts.length < 3) {
      latParts.add(0);
    }

    for (int i = 0; i < 3; i++) {
      if (latParts[i] > curParts[i]) {
        return true;
      }
      if (latParts[i] < curParts[i]) {
        return false;
      }
    }

    if (currentBuild != null && latestBuild != null) {
      return latestBuild > currentBuild;
    }

    return false;
  }
}
