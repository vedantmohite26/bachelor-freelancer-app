## 2026-06-21 - Service-level Future Caching in Flutter
**Learning:** Storing the `Future` itself in a `Map` rather than the resolved value prevents "cache stampedes" where multiple widgets (like `ReviewCard` in a list) trigger the same network request simultaneously before the first one resolves.
**Action:** Use `Map<String, Future<T>>` for service-level caching of asynchronous data.

## 2026-06-21 - CustomScrollView for Virtualization
**Learning:** `SingleChildScrollView` + `Column` + `ListView(shrinkWrap: true)` is a major performance bottleneck as it builds all items at once. `CustomScrollView` with `SliverList` restores virtualization (O(visible) vs O(N)).
**Action:** Replace nested scrollable patterns with `CustomScrollView` and slivers for long or dynamic lists.
