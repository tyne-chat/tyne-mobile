// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/profile/domain/persona_color.dart';

void main() {
  group('resolvePersonaColor', () {
    test('uses the accent colour when one is set, whatever the avatar', () {
      expect(
        resolvePersonaColor(
          color: 0x55ff55,
          avatarColor: 0x8f1e1e,
          avatarHash: 'a1b2c3d4',
        ),
        0x55ff55,
      );
      expect(
        resolvePersonaColor(
          color: 0x55ff55,
          avatarColor: null,
          avatarHash: null,
        ),
        0x55ff55,
      );
    });

    // tyne-chat/tyne#254: drawn as its profile is.
    test("falls back to the colour of the persona's own avatar", () {
      expect(
        resolvePersonaColor(
          color: null,
          avatarColor: 0x8f1e1e,
          avatarHash: 'a1b2c3d4',
        ),
        0x8f1e1e,
      );
      expect(
        resolvePersonaColor(
          color: 0,
          avatarColor: 0x8f1e1e,
          avatarHash: 'a1b2c3d4',
        ),
        0x8f1e1e,
      );
    });

    test(
      "ignores the avatar colour of a persona showing the account's avatar",
      () {
        expect(
          resolvePersonaColor(
            color: null,
            avatarColor: 0x8f1e1e,
            avatarHash: null,
          ),
          isNull,
        );
        expect(
          resolvePersonaColor(
            color: null,
            avatarColor: 0x8f1e1e,
            avatarHash: '',
          ),
          isNull,
        );
      },
    );

    test('gives nothing when there is no colour to show', () {
      expect(
        resolvePersonaColor(color: null, avatarColor: null, avatarHash: 'a1'),
        isNull,
      );
      expect(
        resolvePersonaColor(color: 0, avatarColor: 0, avatarHash: 'a1'),
        isNull,
      );
    });
  });
}
