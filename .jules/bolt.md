# Bolt's Performance Journal

## 2026-06-21 - Flutter Virtualization and Service Caching
**Learning:** The codebase has multiple instances of the `SingleChildScrollView` + `Column` + `ListView.builder(shrinkWrap: true)` anti-pattern. This disables list virtualization, causing O(N) build time and high memory usage for long lists. Additionally, Firestore distribution fetches were redundant across widget rebuilds.
**Action:** Use `CustomScrollView` with `SliverList` for virtualization. Implement in-memory `Future` caching in services (storing the `Future` itself) to prevent redundant network calls and cache stampedes.

## 2026-06-21 - Memory Recording of Future Caching
**Learning:** Storing the `Future` instead of the result in a service cache allows multiple `FutureBuilder` or `Consumer` widgets to wait for the same underlying request, preventing redundant Firestore reads if multiple widgets request the same data simultaneously.
**Action:** Always prefer `Map<String, Future<T>>` for in-memory service caches in Flutter.
