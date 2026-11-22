import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/updater/fork_whats_new_url.dart';

void main() {
  group('forkWhatsNewUrlFor (tyne-chat/tyne#737)', () {
    test('a published Android build opens its own release notes', () {
      expect(
        forkWhatsNewUrlFor('1.2.25', isAndroid: true),
        'https://github.com/tyne-chat/tyne-mobile/releases/tag/v1.2.25',
      );
      expect(
        forkWhatsNewUrlFor('1.2.25-canary', isAndroid: true),
        'https://github.com/tyne-chat/tyne-mobile/releases/tag/v1.2.25',
      );
    });

    test('a test build opens the list of releases', () {
      expect(
        forkWhatsNewUrlFor('1.2.26-dev.lhf.1', isAndroid: true),
        forkReleasesUrl,
      );
      expect(
        forkWhatsNewUrlFor('1.2.26-dev.lhf.1-canary', isAndroid: true),
        forkReleasesUrl,
      );
      expect(forkWhatsNewUrlFor('', isAndroid: true), forkReleasesUrl);
    });

    test('iOS opens the list of releases', () {
      expect(forkWhatsNewUrlFor('1.2.25', isAndroid: false), forkReleasesUrl);
    });

    test('never points at Fluxer', () {
      expect(
        forkReleasesUrl,
        'https://github.com/tyne-chat/tyne-mobile/releases',
      );
    });
  });
}
