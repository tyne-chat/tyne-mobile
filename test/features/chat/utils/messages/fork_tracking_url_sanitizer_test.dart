import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/chat/utils/messages/fork_tracking_url_sanitizer.dart';

// Fork: the port of the web app's tracking URL sanitizer (tyne-chat/tyne#844). Every expected value
// is what the web app's sanitizeTrackingURL returns for the same input (checked 2026-11-20 by
// running both on 742 links built from the rules: none differed apart from how the parameters
// left in place are encoded).
void main() {
  void expectClean(String input, String expected) =>
      expect(forkSanitizeTrackingUrl(input), expected, reason: input);

  test('per-site parameters', () {
    expectClean(
      'https://open.spotify.com/track/2TSYi0kaRDCnfm6KCd3elT?si=MJp7F-nwRpiKCM6LcmxAXQ&utm_source=copy-link&sci=spotify%3Acard-config%3A4cabGfRP3k6ODiB2bxSIH4',
      'https://open.spotify.com/track/2TSYi0kaRDCnfm6KCd3elT?sci=spotify%3Acard-config%3A4cabGfRP3k6ODiB2bxSIH4',
    );
    expectClean(
      'https://open.spotify.com/track/abc?SI=x&go=1&nd=1&context=c',
      'https://open.spotify.com/track/abc?SI=x&go=1&nd=1',
    );
    expectClean(
      'https://www.youtube.com/watch?v=dQw4w9WgXcQ&si=abc&pp=x&is=y&t=42',
      'https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=42',
    );
    expectClean(
      'https://www.youtube-nocookie.com/embed/x?si=abc',
      'https://www.youtube-nocookie.com/embed/x',
    );
    expectClean(
      'https://edition.cnn.com/x?hpt=1&iid=2',
      'https://edition.cnn.com/x',
    );
    expectClean(
      'https://hashnode.com/p/a?keep=1&source=v',
      'https://hashnode.com/p/a?keep=1',
    );
  });

  test('global parameters, fragments and encodings', () {
    expectClean(
      'https://example.com/a?fbclid=abc&gclid=1',
      'https://example.com/a',
    );
    expectClean('https://example.com?utm_source=x', 'https://example.com/');
    expectClean('https://example.com/?utm_source=x#', 'https://example.com/#');
    expectClean(
      'https://example.com/a?utm_source=x#top',
      'https://example.com/a#top',
    );
    expectClean(
      'https://example.com/a?b=%E2%9C%93&utm_medium=x&c=a+b',
      'https://example.com/a?b=%E2%9C%93&c=a+b',
    );
    expectClean(
      'https://user:pw@example.com:8443/a?utm_source=x',
      'https://user:pw@example.com:8443/a',
    );
  });

  test('a link without tracking is returned as it was', () {
    const List<String> untouched = [
      'https://example.com/a?b=1',
      'https://example.com/p/a?keep=a+b%20c#frag',
      'not a link',
      'ftp://example.com/a?utm_source=x',
    ];
    for (final String link in untouched) {
      expectClean(link, link);
    }
  });

  test('excluded hosts are left alone', () {
    expectClean(
      'https://e.newsletters.cnn.com/x?hpt=1&utm_source=n',
      'https://e.newsletters.cnn.com/x?hpt=1&utm_source=n',
    );
  });

  test('redirect wrappers are unwrapped and the target cleaned', () {
    expectClean(
      'https://l.facebook.com/l.php?u=https%3A%2F%2Fexample.org%2F%3Ffbclid%3Dabc&h=AT0',
      'https://example.org/',
    );
    expectClean(
      'https://www.tiktok.com/link/v2?target=https%3A%2F%2Fexample.org%2Ft',
      'https://example.org/t',
    );
  });

  test('path parts and AMP wrappers', () {
    expectClean(
      'https://www.amazon.com/dp/B000/ref=sr_1_1?keywords=x&qid=1&sr=8-1&th=1',
      'https://www.amazon.com/dp/B000?th=1',
    );
    expectClean(
      'https://amp.cnn.com/cnn/story/1?utm_source=a',
      'https://www.cnn.com/story/1',
    );
    expectClean(
      'https://m.thewire.in/article/story/1?utm_source=a',
      'https://thewire.in/story/1',
    );
    expectClean(
      'https://awstrack.me/L0/https:%2F%2Fexample.org%2Faws/1/abc',
      'https://example.org/aws/1/abc',
    );
    expectClean(
      'https://click.pstmrk.it/2s/example.org%2Fpm/abc',
      'https://example.org/pm',
    );
  });

  test('encoded targets', () {
    expectClean(
      'https://www.twitch.tv/r/e/eyJuYW1lIjoidHdpdGNoX2Zhdm9yaXRlX3VwIiwiY2hhbm5lbCI6InNvbWVib2R5In0=',
      'https://www.twitch.tv/somebody',
    );
    expectClean(
      'https://patchbot.io/click/YXxifGh0dHBzJTNBJTJGJTJGZXhhbXBsZS5vcmclMkZwYXRjaA==',
      'https://example.org/patch',
    );
    expectClean(
      'https://click.redditmail.com/CL0/https:%2F%2Fwww.reddit.com%2Fr%2Fx/1/abc',
      'https://www.reddit.com/r/x',
    );
    expectClean(
      'https://steam.gs/x/https://store.steampowered.com/app/1%3Eutm_source=a',
      'https://steam.gs/x/https://store.steampowered.com/app/1',
    );
    expectClean(
      'https://stardockentertainment.info/x/aHR0cHM6Ly93d3cueW91dHViZS5jb20vd2F0Y2g+dj1hYmM=',
      'https://www.youtube.com/watch?v=abc',
    );
    expectClean(
      'https://0yxjo.mjt.lu/lnk/x/aHR0cHM6Ly9leGFtcGxlLm9yZy9tanQ=',
      'https://example.org/mjt',
    );
  });

  test('empty parameter values on sites that drop them', () {
    expectClean(
      'https://www.fernsehlotterie.de/x?a=&b=1&c=',
      'https://www.fernsehlotterie.de/x?a&b=1&c',
    );
  });
}
