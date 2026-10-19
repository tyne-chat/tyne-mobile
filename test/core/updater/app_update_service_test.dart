// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:convert';
import 'dart:io';

import 'package:cryptography/dart.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/updater/app_update_info.dart';
import 'package:fluxer_app/core/updater/app_update_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

class _MockDioAdapter implements HttpClientAdapter {
  _MockDioAdapter(this.handler);

  final ResponseBody Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

const String _releaseUrl =
    'https://github.com/tyne-chat/tyne-mobile/releases/download/v2.0.0/tyne-v2.0.0.apk';

String _sha256Hex(String data) => const DartSha256()
    .hashSync(utf8.encode(data))
    .bytes
    .map((int b) => b.toRadixString(16).padLeft(2, '0'))
    .join();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Directory? tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('app_update_service_test');
    const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathChannel, (call) async {
          if (call.method == 'getTemporaryDirectory') {
            return tempDir?.path;
          }
          return null;
        });

    PackageInfo.setMockInitialValues(
      appName: 'Fluxer',
      packageName: 'com.fluxer.app',
      version: '1.0.0',
      buildNumber: '10',
      buildSignature: '',
    );
  });

  tearDown(() {
    AppUpdateService.platformOverride = null;
    const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathChannel, null);

    const installChannel = MethodChannel('fluxer_app/app_install');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(installChannel, null);

    final dir = tempDir;
    if (dir != null && dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  group('AppUpdateInfo', () {
    test('formattedFileSize handles zero, negative, and positive sizes', () {
      const infoZero = AppUpdateInfo(
        tagName: 'v1.0.1',
        version: '1.0.1',
        title: 'Release 1.0.1',
        releaseNotes: 'Bugfixes',
        downloadUrl: 'https://example.com/app.apk',
        fileName: 'fluxer.apk',
        fileSizeBytes: 0,
        sha256: '',
      );
      expect(infoZero.formattedFileSize, isEmpty);

      const infoNegative = AppUpdateInfo(
        tagName: 'v1.0.1',
        version: '1.0.1',
        title: 'Release 1.0.1',
        releaseNotes: 'Bugfixes',
        downloadUrl: 'https://example.com/app.apk',
        fileName: 'fluxer.apk',
        fileSizeBytes: -100,
        sha256: '',
      );
      expect(infoNegative.formattedFileSize, isEmpty);

      const infoPositive = AppUpdateInfo(
        tagName: 'v1.0.1',
        version: '1.0.1',
        title: 'Release 1.0.1',
        releaseNotes: 'Bugfixes',
        downloadUrl: 'https://example.com/app.apk',
        fileName: 'fluxer.apk',
        fileSizeBytes: 20 * 1024 * 1024,
        sha256: '',
      );
      expect(infoPositive.formattedFileSize, '20.0 MB');
    });
  });

  group('AppUpdateService.isSupportedPlatform', () {
    test('reflects platformOverride when set', () {
      AppUpdateService.platformOverride = true;
      expect(AppUpdateService.isSupportedPlatform(), isTrue);

      AppUpdateService.platformOverride = false;
      expect(AppUpdateService.isSupportedPlatform(), isFalse);

      AppUpdateService.platformOverride = null;
      expect(AppUpdateService.isSupportedPlatform(), Platform.isAndroid);
    });
  });

  group('AppUpdateService.cleanVersion', () {
    test('cleans leading v and trailing metadata', () {
      expect(AppUpdateService.cleanVersion('v1.0.22'), '1.0.22');
      expect(AppUpdateService.cleanVersion('V1.0.22'), '1.0.22');
      expect(AppUpdateService.cleanVersion('1.0.23-canary'), '1.0.23');
      expect(AppUpdateService.cleanVersion('1.0.23-beta.1'), '1.0.23');
      expect(AppUpdateService.cleanVersion('1.0.23+24'), '1.0.23');
      expect(AppUpdateService.cleanVersion('v1.0.23-canary+24'), '1.0.23');
      expect(AppUpdateService.cleanVersion('  v2.1.0  '), '2.1.0');
    });
  });

  group('AppUpdateService.isNewerVersion', () {
    test(
      'current version with -canary suffix is not older than lower release',
      () {
        final bool newer = AppUpdateService.isNewerVersion(
          currentVersion: '1.0.23-canary',
          latestVersion: '1.0.22',
          currentBuild: 24,
        );
        expect(newer, isFalse);
      },
    );

    test(
      'current version with -canary suffix detects genuinely newer release',
      () {
        final bool newer = AppUpdateService.isNewerVersion(
          currentVersion: '1.0.23-canary',
          latestVersion: '1.0.24',
          currentBuild: 24,
        );
        expect(newer, isTrue);
      },
    );

    test('detects major and minor version bumps', () {
      expect(
        AppUpdateService.isNewerVersion(
          currentVersion: '1.2.3',
          latestVersion: '2.0.0',
        ),
        isTrue,
      );
      expect(
        AppUpdateService.isNewerVersion(
          currentVersion: '1.2.3',
          latestVersion: '1.3.0',
        ),
        isTrue,
      );
      expect(
        AppUpdateService.isNewerVersion(
          currentVersion: '2.0.0',
          latestVersion: '1.9.9',
        ),
        isFalse,
      );
    });

    test('handles versions with fewer than 3 segments', () {
      expect(
        AppUpdateService.isNewerVersion(
          currentVersion: '1.0',
          latestVersion: '1.0.1',
        ),
        isTrue,
      );
      expect(
        AppUpdateService.isNewerVersion(
          currentVersion: '1',
          latestVersion: '1.0.0',
        ),
        isFalse,
      );
    });

    test('same version compares build numbers if available', () {
      expect(
        AppUpdateService.isNewerVersion(
          currentVersion: '1.0.23-canary',
          latestVersion: '1.0.23',
          currentBuild: 24,
          latestBuild: 25,
        ),
        isTrue,
      );

      expect(
        AppUpdateService.isNewerVersion(
          currentVersion: '1.0.23-canary',
          latestVersion: '1.0.23',
          currentBuild: 24,
          latestBuild: 24,
        ),
        isFalse,
      );

      expect(
        AppUpdateService.isNewerVersion(
          currentVersion: '1.0.23-canary',
          latestVersion: '1.0.23',
          currentBuild: 24,
        ),
        isFalse,
      );
    });

    test('older test build (1.0.21) sees 1.0.22 as newer', () {
      expect(
        AppUpdateService.isNewerVersion(
          currentVersion: '1.0.21-canary',
          latestVersion: '1.0.22',
          currentBuild: 20,
          latestBuild: 23,
        ),
        isTrue,
      );
    });
  });

  group('AppUpdateService.checkForUpdate', () {
    test('returns null when platform is not supported', () async {
      AppUpdateService.platformOverride = false;
      final service = AppUpdateService();
      final result = await service.checkForUpdate();
      expect(result, isNull);
    });

    test('returns null when response data is not a Map', () async {
      AppUpdateService.platformOverride = true;
      final dio = Dio()
        ..httpClientAdapter = _MockDioAdapter((options) {
          return ResponseBody.fromString(
            '["not", "a", "map"]',
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        });

      final service = AppUpdateService(dio: dio);
      final result = await service.checkForUpdate();
      expect(result, isNull);
    });

    test('returns null when assets do not contain an .apk file', () async {
      AppUpdateService.platformOverride = true;
      final dio = Dio()
        ..httpClientAdapter = _MockDioAdapter((options) {
          final payload = {
            'tag_name': 'v2.0.0',
            'name': 'Release 2.0.0',
            'body': 'Notes',
            'assets': [
              {
                'name': 'fluxer.tar.gz',
                'browser_download_url': 'https://example.com/app.tar.gz',
              },
              {
                'name': 'source.zip',
                'browser_download_url': 'https://example.com/source.zip',
              },
            ],
          };
          return ResponseBody.fromString(
            jsonEncode(payload),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        });

      final service = AppUpdateService(dio: dio);
      final result = await service.checkForUpdate();
      expect(result, isNull);
    });

    test(
      'returns null when release tag is not newer than current package version',
      () async {
        AppUpdateService.platformOverride = true;
        final dio = Dio()
          ..httpClientAdapter = _MockDioAdapter((options) {
            final payload = {
              'tag_name': 'v0.9.0',
              'name': 'Release 0.9.0',
              'body': 'Older release',
              'assets': [
                {
                  'name': 'fluxer.apk',
                  'browser_download_url': 'https://example.com/fluxer.apk',
                  'size': 123456,
                },
              ],
            };
            return ResponseBody.fromString(
              jsonEncode(payload),
              200,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            );
          });

        final service = AppUpdateService(dio: dio);
        final result = await service.checkForUpdate();
        expect(result, isNull);
      },
    );

    test('returns null when dio throws an error', () async {
      AppUpdateService.platformOverride = true;
      final dio = Dio()
        ..httpClientAdapter = _MockDioAdapter((options) {
          throw DioException(
            requestOptions: options,
            error: 'Connection refused',
          );
        });

      final service = AppUpdateService(dio: dio);
      final result = await service.checkForUpdate();
      expect(result, isNull);
    });

    test(
      'returns populated AppUpdateInfo when newer release with APK is found',
      () async {
        AppUpdateService.platformOverride = true;
        final dio = Dio()
          ..httpClientAdapter = _MockDioAdapter((options) {
            final payload = {
              'tag_name': 'v2.0.0+15',
              'name': 'Fluxer v2.0.0',
              'body': 'Exciting new features and bugfixes.',
              'published_at': '2026-09-20T12:00:00Z',
              'assets': [
                {
                  'name': 'fluxer-release.apk',
                  'browser_download_url': _releaseUrl,
                  'size': 45 * 1024 * 1024,
                  'digest': 'sha256:${'AB' * 32}',
                },
              ],
            };
            return ResponseBody.fromString(
              jsonEncode(payload),
              200,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            );
          });

        final service = AppUpdateService(dio: dio);
        final result = await service.checkForUpdate();

        expect(result, isNotNull);
        expect(result!.tagName, 'v2.0.0+15');
        expect(result.version, '2.0.0');
        expect(result.buildNumber, 15);
        expect(result.title, 'Fluxer v2.0.0');
        expect(result.releaseNotes, 'Exciting new features and bugfixes.');
        expect(result.downloadUrl, _releaseUrl);
        expect(result.sha256, 'ab' * 32);
        expect(result.fileName, 'fluxer-release.apk');
        expect(result.fileSizeBytes, 45 * 1024 * 1024);
        expect(result.publishedAt, DateTime.utc(2026, 9, 20, 12));
      },
    );
  });

  group('AppUpdateService unverifiable releases', () {
    Future<AppUpdateInfo?> check(Map<String, Object?> asset) {
      AppUpdateService.platformOverride = true;
      final dio = Dio()
        ..httpClientAdapter = _MockDioAdapter((options) {
          return ResponseBody.fromString(
            jsonEncode({
              'tag_name': 'v2.0.0',
              'assets': [
                {
                  'name': 'tyne-v2.0.0.apk',
                  'browser_download_url': _releaseUrl,
                  'size': 1000,
                  'digest': 'sha256:${'ab' * 32}',
                  ...asset,
                },
              ],
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        });
      return AppUpdateService(dio: dio).checkForUpdate();
    }

    test('offers a release with a trusted URL, a size and a digest', () async {
      expect(await check({}), isNotNull);
    });

    test('ignores a release whose APK is hosted elsewhere', () async {
      expect(
        await check({
          'browser_download_url': 'https://example.com/tyne-v2.0.0.apk',
        }),
        isNull,
      );
    });

    test('ignores a release without a usable digest or size', () async {
      expect(await check({'digest': null}), isNull);
      expect(await check({'digest': 'sha256:abcd'}), isNull);
      expect(await check({'digest': 'md5:${'ab' * 32}'}), isNull);
      expect(await check({'size': 0}), isNull);
    });

    test(
      'isTrustedDownloadUrl only accepts https assets of the release repo',
      () {
        expect(AppUpdateService.isTrustedDownloadUrl(_releaseUrl), isTrue);
        for (final String url in <String>[
          '',
          'not a url',
          _releaseUrl.replaceFirst('https', 'http'),
          _releaseUrl.replaceFirst('github.com', 'github.com.evil.example'),
          _releaseUrl.replaceFirst('github.com', 'evil@github.com'),
          _releaseUrl.replaceFirst('github.com', 'github.com:8443'),
          _releaseUrl.replaceFirst('tyne-chat', 'someone-else'),
          'https://github.com/tyne-chat/tyne-mobile/releases/download/../../../../evil/x/releases/download/v1/a.apk',
          'file:///sdcard/evil.apk',
        ]) {
          expect(
            AppUpdateService.isTrustedDownloadUrl(url),
            isFalse,
            reason: url,
          );
        }
      },
    );
  });

  group('AppUpdateService.downloadUpdate', () {
    const fileData = 'test-apk-binary-content';

    AppUpdateInfo infoFor({
      String downloadUrl = _releaseUrl,
      String fileName = 'tyne-v2.0.0.apk',
      int? fileSizeBytes,
      String? sha256,
    }) {
      return AppUpdateInfo(
        tagName: 'v2.0.0',
        version: '2.0.0',
        title: 'Release 2.0.0',
        releaseNotes: 'Notes',
        downloadUrl: downloadUrl,
        fileName: fileName,
        fileSizeBytes: fileSizeBytes ?? fileData.length,
        sha256: sha256 ?? _sha256Hex(fileData),
      );
    }

    Dio dioServing(String body, {void Function()? onRequest}) {
      final dio = Dio()
        ..httpClientAdapter = _MockDioAdapter((options) {
          onRequest?.call();
          return ResponseBody.fromString(
            body,
            200,
            headers: {
              Headers.contentLengthHeader: ['${body.length}'],
            },
          );
        });
      return dio;
    }

    List<String> tempFileNames() => tempDir!
        .listSync(recursive: true)
        .whereType<File>()
        .map((File e) => e.path.substring(tempDir!.path.length + 1))
        .toList();

    test(
      'downloads a matching file under a fixed name and reports progress',
      () async {
        // A previous download is replaced.
        File('${tempDir!.path}/updates/tyne-update.apk')
          ..createSync(recursive: true)
          ..writeAsStringSync('old-content');

        final service = AppUpdateService(dio: dioServing(fileData));
        double lastProgress = 0;
        int lastReceived = 0;
        int lastTotal = 0;

        final File? downloaded = await service.downloadUpdate(
          infoFor(),
          onProgress: (progress, received, total) {
            lastProgress = progress;
            lastReceived = received;
            lastTotal = total;
          },
        );

        expect(downloaded, isNotNull);
        expect(downloaded!.path, '${tempDir!.path}/updates/tyne-update.apk');
        expect(downloaded.readAsStringSync(), fileData);
        expect(tempFileNames(), ['updates/tyne-update.apk']);
        expect(lastReceived, fileData.length);
        expect(lastTotal, fileData.length);
        expect(lastProgress, 1.0);
      },
    );

    test('does not use the asset name as a path', () async {
      final service = AppUpdateService(dio: dioServing(fileData));
      final File? downloaded = await service.downloadUpdate(
        infoFor(fileName: '../../evil.apk'),
      );
      expect(downloaded!.path, '${tempDir!.path}/updates/tyne-update.apk');
    });

    test('discards a download whose hash does not match', () async {
      final service = AppUpdateService(
        dio: dioServing('tampered-binary-content'),
      );
      expect('tampered-binary-content'.length, fileData.length);
      expect(await service.downloadUpdate(infoFor()), isNull);
      expect(tempFileNames(), isEmpty);
    });

    test('discards a truncated or oversized download', () async {
      for (final String body in <String>['test-apk', '$fileData-and-more']) {
        final service = AppUpdateService(dio: dioServing(body));
        final File? downloaded = await service.downloadUpdate(
          infoFor(sha256: _sha256Hex(body)),
        );
        expect(downloaded, isNull, reason: body);
        expect(tempFileNames(), isEmpty, reason: body);
      }
    });

    test('does not request an untrusted URL', () async {
      int requests = 0;
      final service = AppUpdateService(
        dio: dioServing(fileData, onRequest: () => requests++),
      );
      expect(
        await service.downloadUpdate(
          infoFor(downloadUrl: 'https://example.com/tyne-v2.0.0.apk'),
        ),
        isNull,
      );
      expect(requests, 0);
    });

    test('returns null when download fails with error', () async {
      final dio = Dio()
        ..httpClientAdapter = _MockDioAdapter((options) {
          throw DioException(
            requestOptions: options,
            error: 'Download timeout',
          );
        });

      final service = AppUpdateService(dio: dio);
      expect(await service.downloadUpdate(infoFor()), isNull);
    });
  });

  group('AppUpdateService MethodChannel platform methods', () {
    test(
      'canRequestPackageInstalls returns false when unsupported or channel error',
      () async {
        AppUpdateService.platformOverride = false;
        final service = AppUpdateService();
        expect(await service.canRequestPackageInstalls(), isFalse);

        AppUpdateService.platformOverride = true;
        const installChannel = MethodChannel('fluxer_app/app_install');
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(installChannel, (call) async {
              if (call.method == 'canRequestPackageInstalls') {
                return true;
              }
              return null;
            });
        expect(await service.canRequestPackageInstalls(), isTrue);

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              installChannel,
              (call) => Future<Object?>.error(
                PlatformException(code: 'ERR_PERMISSION', message: 'Failed'),
              ),
            );
        expect(await service.canRequestPackageInstalls(), isFalse);
      },
    );

    test(
      'openInstallPermissionSettings returns channel result or false on error',
      () async {
        AppUpdateService.platformOverride = false;
        final service = AppUpdateService();
        expect(await service.openInstallPermissionSettings(), isFalse);

        AppUpdateService.platformOverride = true;
        const installChannel = MethodChannel('fluxer_app/app_install');
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(installChannel, (call) async {
              if (call.method == 'openInstallPermissionSettings') {
                return true;
              }
              return null;
            });
        expect(await service.openInstallPermissionSettings(), isTrue);

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              installChannel,
              (call) => Future<Object?>.error(
                PlatformException(code: 'ERR_SETTINGS', message: 'Failed'),
              ),
            );
        expect(await service.openInstallPermissionSettings(), isFalse);
      },
    );

    test('installUpdate calls installPackage with filePath', () async {
      AppUpdateService.platformOverride = false;
      final service = AppUpdateService();
      expect(await service.installUpdate('/tmp/test.apk'), isFalse);

      AppUpdateService.platformOverride = true;
      const installChannel = MethodChannel('fluxer_app/app_install');
      dynamic passedArguments;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(installChannel, (call) async {
            if (call.method == 'installPackage') {
              passedArguments = call.arguments;
              return true;
            }
            return null;
          });

      expect(await service.installUpdate('/data/local/tmp/app.apk'), isTrue);
      expect(passedArguments, {'filePath': '/data/local/tmp/app.apk'});

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            installChannel,
            (call) => Future<Object?>.error(
              PlatformException(code: 'ERR_INSTALL', message: 'Failed'),
            ),
          );
      expect(await service.installUpdate('/data/local/tmp/app.apk'), isFalse);
    });
  });
}
