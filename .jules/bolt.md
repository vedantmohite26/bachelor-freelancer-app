## 2026-06-15 - Async Cache Invalidation Race Conditions
**Learning:** In Flutter/Dart service-level caching, removing an item from a `Map<String, Future>` cache BEFORE awaiting a Firestore update creates a race condition where concurrent reads might re-populate the cache with stale data before the write completes.
**Action:** Always invalidate the cache entry AFTER the asynchronous write operation has successfully completed to ensure the next read fetches the fresh data.

## 2026-06-15 - Flutter UI Virtualization
**Learning:** Using `SingleChildScrollView` with a nested `ListView(shrinkWrap: true)` disables Flutter's list virtualization, causing $O(N)$ build and memory overhead.
**Action:** Use `CustomScrollView` with `SliverList` or `SliverFixedExtentList` for lists with dynamic data to ensure $O(visible)$ performance.
