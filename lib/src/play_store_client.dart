import 'package:dio/dio.dart';
import 'package:play_store_info/src/play_store_app_info.dart';
import 'package:play_store_info/src/play_store_page_parser.dart';

/// Looks up public Play Store metadata by application id.
///
/// This reads the public store page (no API key, no cost). It is unofficial:
/// Google may change the page or rate-limit requests, so callers should treat
/// a null result as "unknown" and cache successful results.
class PlayStoreClient {
  PlayStoreClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ),
          );

  final Dio _dio;

  static const _userAgent =
      'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/124.0 Mobile Safari/537.36';

  /// Returns info for [applicationId], or null if the app does not exist,
  /// the request fails, or the page cannot be understood.
  Future<PlayStoreAppInfo?> fetchAppInfo(
    String applicationId, {
    String language = 'en',
    CancelToken? cancelToken,
  }) async {
    final id = applicationId.trim();

    if (id.isEmpty) return null;

    try {
      final response = await _dio.get<String>(
        'https://play.google.com/store/apps/details',
        queryParameters: {'id': id, 'hl': language},
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.plain,
          headers: {'User-Agent': _userAgent},
          validateStatus: (status) => status == 200,
        ),
      );

      final html = response.data;

      if (html == null || html.isEmpty) return null;

      return parsePlayStorePage(html, id);
    } on DioException {
      return null;
    }
  }
}
