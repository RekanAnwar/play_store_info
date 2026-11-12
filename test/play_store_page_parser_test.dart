import 'package:test/test.dart';
import 'package:play_store_info/src/play_store_page_parser.dart';

void main() {
  layeredFallbackTests();
  const id = 'com.example.app';

  test('parses JSON-LD', () {
    const html = '''
<html><head>
<script type="application/ld+json" nonce="x">{"@context":"https://schema.org","@type":"SoftwareApplication","name":"My App","description":"Desc","image":"https://img/abc","applicationCategory":"TOOLS","contentRating":"Rated for 3+","author":{"@type":"Person","name":"Dev","url":"http://dev.com/"},"aggregateRating":{"ratingValue":"4.5","ratingCount":"100"},"offers":[{"price":"0","priceCurrency":"USD"}]}</script>
</head></html>''';

    final info = parsePlayStorePage(html, id)!;

    expect(info.name, 'My App');
    expect(info.description, 'Desc');
    expect(info.iconUrlWithSize(128), 'https://img/abc=s128');
    expect(info.category, 'TOOLS');
    expect(info.developerName, 'Dev');
    expect(info.ratingValue, 4.5);
    expect(info.ratingCount, 100);
    expect(info.isFree, isTrue);
    expect(info.priceCurrency, 'USD');
  });

  test('falls back to meta tags', () {
    const html = '''
<meta property="og:title" content="Tom &amp; Jerry - Apps on Google Play">
<meta property="og:image" content="https://play-lh.googleusercontent.com/abc=s0-br30">''';

    final info = parsePlayStorePage(html, id)!;

    expect(info.name, 'Tom & Jerry');
    expect(info.iconUrl, 'https://play-lh.googleusercontent.com/abc');
    expect(info.developerName, isNull);
  });

  test('returns null for unrelated pages', () {
    expect(parsePlayStorePage('<html>Not found</html>', id), isNull);
  });
}

void layeredFallbackTests() {
  const id = 'com.example.app';

  group('survives layout changes', () {
    test('JSON-LD removed: meta and microdata still give the data', () {
      const html = '''
<title id="x">My App - Apps on Google Play</title>
<meta property="og:title" content="My App - Apps on Google Play">
<meta property="og:image" content="https://play-lh.googleusercontent.com/abc=s0-br30">
<meta itemprop="genre" content="Tools">
<meta itemprop="price" content="0">''';

      final info = parsePlayStorePage(html, id)!;

      expect(info.name, 'My App');
      expect(info.iconUrl, 'https://play-lh.googleusercontent.com/abc');
      expect(info.category, 'Tools');
      expect(info.isFree, isTrue);
    });

    test('only <title> and an icon <img> remain', () {
      const html = '''
<title>My App - Apps on Google Play</title>
<img src="https://play-lh.googleusercontent.com/shot=w100" alt="Screenshot">
<img src="https://play-lh.googleusercontent.com/icon=s48" alt="Icon image">''';

      final info = parsePlayStorePage(html, id)!;

      expect(info.name, 'My App');
      expect(info.iconUrl, 'https://play-lh.googleusercontent.com/icon');
    });

    test('broken JSON-LD is skipped, not fatal', () {
      const html = '''
<script type="application/ld+json">{not json</script>
<meta property="og:title" content="My App - Apps on Google Play">''';

      expect(parsePlayStorePage(html, id)!.name, 'My App');
    });

    test('missing fields are filled from lower-priority sources', () {
      const html = '''
<script type="application/ld+json">{"@type":"SoftwareApplication","name":"My App"}</script>
<meta property="og:image" content="https://play-lh.googleusercontent.com/abc=s0">''';

      final info = parsePlayStorePage(html, id)!;

      expect(info.name, 'My App');
      expect(info.iconUrl, 'https://play-lh.googleusercontent.com/abc');
    });
  });
}
