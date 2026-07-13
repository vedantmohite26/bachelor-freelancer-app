## 2026-07-13 - [Virtualization & Service Caching]
**Learning:** Nesting `ListView.builder` with `shrinkWrap: true` inside a `SingleChildScrollView` (or any scrollable) disables Flutter's list virtualization, causing the entire list to be rendered at once. This significantly degrades performance as the list grows. Additionally, redundant Firestore reads in UI components like `RatingSummaryCard` can be mitigated by caching the `Future` in the service layer.

**Action:** Always prefer `CustomScrollView` with `SliverList.builder` for long lists to maintain virtualization. In service-level caches, store the `Future` itself (e.g., `Map<String, Future<T>>`) to handle concurrent requests gracefully and reduce network overhead.
