## 0.1.0

- Initial release.
- `PlayStoreClient.fetchAppInfo` returns a nullable `PlayStoreAppInfo`
  (name, description, icon, category, content rating, developer, rating,
  price, store URL).
- Layered extraction (JSON-LD, Open Graph, microdata, `<title>`/icon image),
  merged field by field so a change to one part of the page does not lose
  everything.
