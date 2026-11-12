import 'dart:convert';

import 'package:play_store_info/src/play_store_app_info.dart';

/// Extracts [PlayStoreAppInfo] from the HTML of a Play Store details page.
///
/// Instead of relying on one layout, several independent extractors run, each
/// reading a signal Google has strong reasons to keep stable (SEO and link
/// preview markup, not the visual UI):
///
/// 1. schema.org JSON-LD (richest)
/// 2. Open Graph meta tags
/// 3. `itemprop` microdata
/// 4. `<title>` tag and the first Play image URL (last resort)
///
/// Results are merged field by field, so one extractor breaking only loses the
/// fields that nobody else can supply. Returns null when no name is found.
PlayStoreAppInfo? parsePlayStorePage(String html, String applicationId) {
  final fields = _Fields()
    ..fillFrom(_jsonLd(html))
    ..fillFrom(_openGraph(html))
    ..fillFrom(_microdata(html))
    ..fillFrom(_lastResort(html));

  final name = fields.name;
  if (name == null) return null;

  return PlayStoreAppInfo(
    applicationId: applicationId,
    name: name,
    description: fields.description,
    iconUrl: fields.iconUrl,
    category: fields.category,
    contentRating: fields.contentRating,
    developerName: fields.developerName,
    developerUrl: fields.developerUrl,
    ratingValue: fields.ratingValue,
    ratingCount: fields.ratingCount,
    price: fields.price,
    priceCurrency: fields.priceCurrency,
    storeUrl: fields.storeUrl,
  );
}

/// Mutable bag of optional fields; earlier extractors win.
class _Fields {
  String? name;
  String? description;
  String? iconUrl;
  String? category;
  String? contentRating;
  String? developerName;
  String? developerUrl;
  double? ratingValue;
  int? ratingCount;
  double? price;
  String? priceCurrency;
  String? storeUrl;

  void fillFrom(_Fields? other) {
    if (other == null) return;
    name ??= other.name;
    description ??= other.description;
    iconUrl ??= other.iconUrl;
    category ??= other.category;
    contentRating ??= other.contentRating;
    developerName ??= other.developerName;
    developerUrl ??= other.developerUrl;
    ratingValue ??= other.ratingValue;
    ratingCount ??= other.ratingCount;
    price ??= other.price;
    priceCurrency ??= other.priceCurrency;
    storeUrl ??= other.storeUrl;
  }
}

// ---------------------------------------------------------------- JSON-LD --

final _jsonLdPattern = RegExp(
  r'<script[^>]*type="application/ld\+json"[^>]*>(.*?)</script>',
  dotAll: true,
);

_Fields? _jsonLd(String html) {
  for (final match in _jsonLdPattern.allMatches(html)) {
    try {
      final decoded = jsonDecode(match.group(1)!);
      final candidates = decoded is List ? decoded : [decoded];
      for (final candidate in candidates) {
        if (candidate is Map<String, dynamic> &&
            candidate['@type'] == 'SoftwareApplication') {
          return _fromJsonLdData(candidate);
        }
      }
    } on FormatException {
      continue;
    }
  }
  return null;
}

_Fields _fromJsonLdData(Map<String, dynamic> data) {
  final author = data['author'];
  final rating = data['aggregateRating'];
  final offers = data['offers'];
  final offer = offers is List && offers.isNotEmpty ? offers.first : offers;

  return _Fields()
    ..name = _string(data['name'])
    ..description = _string(data['description'])
    ..iconUrl = _cleanIcon(_string(data['image']))
    ..category = _string(data['applicationCategory'])
    ..contentRating = _string(data['contentRating'])
    ..developerName = author is Map ? _string(author['name']) : null
    ..developerUrl = author is Map ? _string(author['url']) : null
    ..ratingValue = rating is Map ? _number(rating['ratingValue']) : null
    ..ratingCount = rating is Map
        ? _number(rating['ratingCount'])?.toInt()
        : null
    ..price = offer is Map ? _number(offer['price']) : null
    ..priceCurrency = offer is Map ? _string(offer['priceCurrency']) : null
    ..storeUrl = _string(data['url']);
}

// ------------------------------------------------------------ Open Graph --

const _titleSuffix = ' - Apps on Google Play';

_Fields? _openGraph(String html) {
  final title =
      _metaContent(html, 'property', 'og:title') ??
      _metaContent(html, 'name', 'twitter:title');
  return _Fields()
    ..name = title == null ? null : _stripTitleSuffix(title)
    ..description =
        _metaContent(html, 'property', 'og:description') ??
        _metaContent(html, 'name', 'twitter:description')
    ..iconUrl = _cleanIcon(
      _metaContent(html, 'property', 'og:image') ??
          _metaContent(html, 'name', 'twitter:image'),
    )
    ..storeUrl = _metaContent(html, 'property', 'og:url');
}

// ------------------------------------------------------------- Microdata --

_Fields? _microdata(String html) {
  final price = _metaContent(html, 'itemprop', 'price');
  return _Fields()
    ..name = _metaContent(html, 'itemprop', 'name')
    ..description = _metaContent(html, 'itemprop', 'description')
    ..category = _metaContent(html, 'itemprop', 'genre')
    ..contentRating = _metaContent(html, 'itemprop', 'contentRating')
    ..price = price == null ? null : double.tryParse(price)
    ..iconUrl = _iconFromImages(html);
}

// ----------------------------------------------------------- Last resort --

_Fields? _lastResort(String html) {
  final title = RegExp(
    '<title[^>]*>([^<]*)</title>',
  ).firstMatch(html)?.group(1);
  return _Fields()
    ..name = title == null ? null : _stripTitleSuffix(_unescapeHtml(title))
    ..iconUrl =
        _iconFromImages(html) ??
        _cleanIcon(_playImagePattern.firstMatch(html)?.group(0));
}

// --------------------------------------------------------------- Helpers --

final _playImagePattern = RegExp(
  r'https://play-lh\.googleusercontent\.com/[A-Za-z0-9_\-]+(?:=[^\s"\\<>]*)?',
);

/// Prefers `<img alt="Icon image">` (the app icon), else null.
String? _iconFromImages(String html) {
  for (final img in RegExp(r'<img\b[^>]*>').allMatches(html)) {
    final tag = img.group(0)!;
    if (!tag.contains('alt="Icon image"')) continue;
    final src = RegExp(r'\bsrc="([^"]+)"').firstMatch(tag)?.group(1);
    final icon = _cleanIcon(src);
    if (icon != null) return icon;
  }
  return null;
}

/// Removes the size suffix (`=s0-br30`, `=w240-h480`...) from an image URL.
String? _cleanIcon(String? url) {
  if (url == null || !url.contains('googleusercontent.com')) return url;
  final cleaned = url.split('=').first;
  return cleaned.isEmpty ? null : cleaned;
}

String _stripTitleSuffix(String title) {
  final trimmed = title.trim();
  return trimmed.endsWith(_titleSuffix)
      ? trimmed.substring(0, trimmed.length - _titleSuffix.length)
      : trimmed;
}

/// Reads `content` of a `<meta {attribute}="{value}" ...>` tag regardless of
/// attribute order.
String? _metaContent(String html, String attribute, String value) {
  final escaped = RegExp.escape(value);
  final patterns = [
    RegExp('<meta[^>]*$attribute="$escaped"[^>]*content="([^"]*)"'),
    RegExp('<meta[^>]*content="([^"]*)"[^>]*$attribute="$escaped"'),
  ];
  for (final pattern in patterns) {
    final found = pattern.firstMatch(html)?.group(1);
    if (found != null && found.isNotEmpty) return _unescapeHtml(found);
  }
  return null;
}

String _unescapeHtml(String value) => value
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&amp;', '&');

String? _string(Object? value) =>
    value is String && value.isNotEmpty ? value : null;

double? _number(Object? value) => switch (value) {
  final num n => n.toDouble(),
  final String s => double.tryParse(s),
  _ => null,
};
