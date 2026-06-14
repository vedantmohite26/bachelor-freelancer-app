## 2026-06-25 - Caching Futures in Flutter Services
**Learning:** Storing the `Future` itself in a service-level `Map` (e.g., `Map<String, Future<T>>`) is a highly effective way to prevent "cache stampedes" and redundant network calls. When multiple UI components (like list items) request the same data simultaneously, they all await the same `Future` instance instead of triggering separate Firestore fetches.
**Action:** Always prefer caching the `Future` rather than the resolved data for asynchronous service-level caches in Flutter to handle concurrent requests gracefully.

## 2026-06-25 - Virtualization vs. shrinkWrap
**Learning:** The `shrinkWrap: true` property on `ListView` or `GridView` inside a `SingleChildScrollView` is a major performance anti-pattern. It disables virtualization and forces the entire list to render at once, resulting in O(N) complexity for both memory and layout.
**Action:** Use `CustomScrollView` with `SliverList` and `SliverToBoxAdapter` to maintain virtualization and O(visible) rendering for complex scrolling layouts.
