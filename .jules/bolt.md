## 2026-06-25 - [Future-based Caching & UI Virtualization]
**Learning:** In-memory caching of the `Future` itself (rather than just the result) in Flutter services prevents "cache stampedes" where multiple concurrent UI components (e.g., in a list) trigger redundant network requests for the same resource before the first one completes. Additionally, replacing `shrinkWrap: true` with `CustomScrollView` + `SliverList` is critical for maintaining O(visible) rendering performance in dynamic lists.

**Action:** Always prefer caching the `Future` object for asynchronous service calls, and use `CustomScrollView` for any screen that combines fixed headers with dynamic lists to ensure virtualization remains enabled.
