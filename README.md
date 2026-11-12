# play_store_info

Look up public Google Play Store details for an Android app by its
application id (package name). No API key, no account.

```dart
import 'package:play_store_info/play_store_info.dart';

final info = await PlayStoreClient().fetchAppInfo('com.google.android.apps.maps');
if (info != null) {
  print(info.name);                 // Google Maps
  print(info.iconUrlWithSize(128)); // https://play-lh.googleusercontent.com/...=s128
}
```

## What you get

`fetchAppInfo` returns a `PlayStoreAppInfo?`:

| Field | Type |
|---|---|
| `applicationId`, `name` | `String` (always present) |
| `description`, `iconUrl`, `category`, `contentRating` | `String?` |
| `developerName`, `developerUrl`, `storeUrl` | `String?` |
| `ratingValue`, `ratingCount` | `double?`, `int?` |
| `price`, `priceCurrency`, `isFree` | `double?`, `String?`, `bool?` |

`iconUrlWithSize(int)` returns the icon as a square image of the given size.

It returns `null` when the app does not exist, the request fails, or the page
cannot be understood. It does not throw for those cases.

## How it stays working

The package reads the public store page. Instead of depending on one layout it
runs several independent extractors (schema.org JSON-LD, Open Graph tags,
`itemprop` microdata, and the `<title>` tag plus icon image) and merges their
results field by field. If Google changes one part of the page, the rest
still fills in the app name and icon.

## Limitations

- **Unofficial.** This is not an official Google API and is not affiliated with
  or endorsed by Google. Google may change the page or rate-limit requests.
  Cache results and treat `null` as "unknown".
- Only data on the public page is available. Install counts, screenshots and
  reviews are not returned.
- Some regions redirect to a consent page; those lookups return `null`.
- Check the Google Play Terms of Service for your use case before relying on
  this in production.

## Detecting breakage

`test_live/` contains a test against the real Play Store. Run
`dart test test_live` on a schedule to find out when Google changes the page.
