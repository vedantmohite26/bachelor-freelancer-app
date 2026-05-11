## 2026-06-25 - Service-level Future Caching in Flutter
**Learning:** Returning the same `Future` instance from a service using `putIfAbsent` prevents redundant Firestore fetches and UI flashing in `FutureBuilder` without requiring complex state management.
**Action:** Use `Map<String, Future<T>>` in services for data that is fetched frequently but changes rarely (like user profiles or aggregate statistics).

## 2026-06-25 - Flutter List Virtualization Anti-pattern
**Learning:** The `SingleChildScrollView` + `ListView(shrinkWrap: true)` pattern disables virtualization, causing O(N) build complexity and massive concurrent network requests when children perform their own fetches.
**Action:** Use `CustomScrollView` with `SliverList` to enable virtualization, reducing initial build time and network load to O(visible).
