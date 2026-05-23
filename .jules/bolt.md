## 2026-06-23 - Flutter Virtualization and Service Caching

**Learning:** Using `SingleChildScrollView` with `ListView.builder(shrinkWrap: true)` is a common anti-pattern in Flutter that completely disables list virtualization, forcing the framework to build and layout all items at once (O(N) complexity). Additionally, UI widgets often trigger redundant Firestore fetches (N+1 query problem) when resolving relational data (like a seeker's name in a review list).

**Action:**
1. Always prefer `CustomScrollView` with `SliverList` for large or dynamic lists to ensure O(visible) rendering performance.
2. Implement in-memory `Future` caching in Service classes to deduplicate concurrent and subsequent requests for the same resource. Always use `.catchError` to prune failed requests from the cache.
