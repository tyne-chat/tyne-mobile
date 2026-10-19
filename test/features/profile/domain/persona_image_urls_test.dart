import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/constants/media_proxy_sizes.dart';
import 'package:fluxer_app/core/media/fluxer_media_url.dart';
import 'package:fluxer_app/features/profile/domain/persona_image_urls.dart';

// A persona's images and the display tag icon are hashes of images stored under
// the owning account. Anything else must give no address: a link would be
// loaded from wherever it points.

const List<String> _notHashes = <String>[
  'https://tracker.example/pixel.png',
  'http://tracker.example/pixel.png',
  '//tracker.example/pixel.png',
  'data:image/png;base64,iVBORw0KGgo=',
  'blob:https://app.example/1234',
  'icon.png',
  '🦊',
  '1A2B3C4D',
  '1a2b3c4',
  'abcdef0123456789abcdef0123456789',
  '../1a2b3c4d',
];

void main() {
  group('isPersonaImageHash', () {
    test('accepts the hashes the server issues', () {
      expect(isPersonaImageHash('1a2b3c4d'), isTrue);
      expect(isPersonaImageHash('a_1a2b3c4d'), isTrue);
    });

    test('refuses everything else', () {
      expect(isPersonaImageHash(null), isFalse);
      expect(isPersonaImageHash(''), isFalse);
      for (final String value in _notHashes) {
        expect(isPersonaImageHash(value), isFalse, reason: value);
      }
    });
  });

  group('personaAvatarUrl', () {
    test('builds the media address under the owning account', () {
      expect(
        personaAvatarUrl(ownerUserId: '42', hash: 'a_1a2b3c4d'),
        FluxerMediaUrl.userAvatar(
          userId: '42',
          hash: 'a_1a2b3c4d',
          animated: true,
        ),
      );
      expect(
        personaAvatarUrl(
          ownerUserId: '42',
          hash: ' 1a2b3c4d ',
          size: MediaProxySizes.avatarProfile,
          animated: false,
        ),
        FluxerMediaUrl.userAvatar(
          userId: '42',
          hash: '1a2b3c4d',
          size: MediaProxySizes.avatarProfile,
        ),
      );
    });

    test('gives no address without a hash or an owner', () {
      expect(personaAvatarUrl(ownerUserId: '42', hash: null), isNull);
      expect(personaAvatarUrl(ownerUserId: '42', hash: ''), isNull);
      expect(personaAvatarUrl(ownerUserId: null, hash: '1a2b3c4d'), isNull);
      expect(personaAvatarUrl(ownerUserId: '', hash: '1a2b3c4d'), isNull);
    });

    test('never passes a value that is not a hash through', () {
      for (final String value in _notHashes) {
        expect(
          personaAvatarUrl(ownerUserId: '42', hash: value),
          isNull,
          reason: value,
        );
      }
    });
  });

  group('personaBannerUrl', () {
    test('builds the media address under the owning account', () {
      expect(
        personaBannerUrl(ownerUserId: '42', hash: '1a2b3c4d'),
        FluxerMediaUrl.userBanner(
          userId: '42',
          hash: '1a2b3c4d',
          animated: true,
        ),
      );
    });

    test('never passes a value that is not a hash through', () {
      for (final String value in _notHashes) {
        expect(
          personaBannerUrl(ownerUserId: '42', hash: value),
          isNull,
          reason: value,
        );
      }
    });
  });

  group('personaTagIconUrl', () {
    test('serves the icon like an avatar of the owning account', () {
      expect(
        personaTagIconUrl(ownerUserId: '42', icon: 'a_1a2b3c4d'),
        FluxerMediaUrl.userAvatar(
          userId: '42',
          hash: 'a_1a2b3c4d',
          animated: true,
        ),
      );
    });

    test('never passes a value that is not a hash through', () {
      for (final String value in _notHashes) {
        expect(
          personaTagIconUrl(ownerUserId: '42', icon: value),
          isNull,
          reason: value,
        );
      }
      expect(personaTagIconUrl(ownerUserId: null, icon: '1a2b3c4d'), isNull);
    });
  });

  group('personaImageHash', () {
    test('passes a hash on, trimmed, for a widget to resolve', () {
      expect(personaImageHash(' a_1a2b3c4d '), 'a_1a2b3c4d');
      expect(personaImageHash(null), isNull);
    });

    test('gives null for anything else', () {
      for (final String value in _notHashes) {
        expect(personaImageHash(value), isNull, reason: value);
      }
    });
  });
}
