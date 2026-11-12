import 'package:test/test.dart';
import 'package:play_store_info/play_store_info.dart';

/// Canary against the real Play Store. Lives outside test/ so the default run skips it.
/// Run: `flutter test test_live` (e.g. nightly CI) to learn immediately when
/// Google changes the page enough to break every extractor.
void main() {
  test('real page still yields name and icon', () async {
    final info = await PlayStoreClient().fetchAppInfo(
      'com.google.android.apps.maps',
    );

    expect(info, isNotNull);
    expect(info!.name, isNotEmpty);
    expect(info.iconUrl, isNotNull);
  });
}
