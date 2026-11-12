import 'package:play_store_info/play_store_info.dart';

Future<void> main() async {
  final client = PlayStoreClient();
  final info = await client.fetchAppInfo('com.google.android.apps.maps');

  if (info == null) {
    print('App not found or Play Store unreachable.');
    return;
  }

  print('Name: ${info.name}');
  print('Developer: ${info.developerName}');
  print('Rating: ${info.ratingValue} (${info.ratingCount} ratings)');
  print('Free: ${info.isFree}');
  print('Icon: ${info.iconUrlWithSize(128)}');
}
