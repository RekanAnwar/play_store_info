/// Public information about an app listed on Google Play.
///
/// Every field except [applicationId] and [name] may be null, because the
/// Play Store page does not always expose it.
class PlayStoreAppInfo {
  const PlayStoreAppInfo({
    required this.applicationId,
    required this.name,
    this.description,
    this.iconUrl,
    this.category,
    this.contentRating,
    this.developerName,
    this.developerUrl,
    this.ratingValue,
    this.ratingCount,
    this.price,
    this.priceCurrency,
    this.storeUrl,
  });

  /// Android package name, e.g. `com.example.app`.
  final String applicationId;

  final String name;
  final String? description;

  /// Icon URL without a size suffix. Use [iconUrlWithSize] to display it.
  final String? iconUrl;

  /// Schema.org category, e.g. `TOOLS`.
  final String? category;

  /// e.g. `Rated for 3+`.
  final String? contentRating;

  final String? developerName;
  final String? developerUrl;

  /// Average rating (0-5).
  final double? ratingValue;
  final int? ratingCount;

  final double? price;
  final String? priceCurrency;
  final String? storeUrl;

  bool? get isFree => price == null ? null : price == 0;

  /// Returns the icon as a square image of [size] pixels, or null if the app
  /// has no icon.
  String? iconUrlWithSize(int size) {
    final url = iconUrl;
    return url == null ? null : '$url=s$size';
  }

  @override
  String toString() =>
      'PlayStoreAppInfo(applicationId: $applicationId, name: $name)';
}
