import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/chat/utils/messages/url_sanitization_utils.dart';

// Fork: messages are cleaned with the web app's tracking rules as well as upstream's list
// (tyne-chat/tyne#844).
void main() {
  test(
    "a shared Spotify link loses si and utm_source, the message's text stays",
    () {
      const String track =
          'https://open.spotify.com/track/2TSYi0kaRDCnfm6KCd3elT';
      const String sci = 'sci=spotify%3Acard-config%3A4cabGfRP3k6ODiB2bxSIH4';
      const String tracking = 'si=MJp7F-nwRpiKCM6LcmxAXQ&utm_source=copy-link';
      expect(
        sanitizeUrlsInContent(
          'If you liked it $track?$tracking&$sci thinking of you!',
        ),
        'If you liked it $track?$sci thinking of you!',
      );
    },
  );

  test('trailing punctuation stays outside the link', () {
    expect(
      sanitizeUrlsInContent('Look: https://www.youtube.com/watch?v=abc&si=x.'),
      'Look: https://www.youtube.com/watch?v=abc.',
    );
  });

  test('links in code spans are left alone', () {
    const String code = '`https://open.spotify.com/track/abc?si=x`';
    expect(sanitizeUrlsInContent(code), code);
  });

  test("upstream's own list still applies after the web's rules", () {
    // share_token is in upstream's list and not in the web's.
    expect(
      sanitizeUrlsInContent(
        'https://example.com/a?share_token=t&utm_source=x&b=1',
      ),
      'https://example.com/a?b=1',
    );
  });

  test('si stays on sites without a rule for it', () {
    const String link = 'https://example.com/page?si=keep';
    expect(sanitizeUrlsInContent(link), link);
  });
}
