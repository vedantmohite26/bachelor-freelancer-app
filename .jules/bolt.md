## 2026-06-21 - Virtualization and Stream Stability in HelperReviewsScreen

**Learning:** Combining `SingleChildScrollView` with `ListView.builder(shrinkWrap: true)` is a common anti-pattern in Flutter that disables list virtualization, forcing O(N) build time. Additionally, creating streams directly in the `build` method leads to redundant listeners and UI flickers.

**Action:** Always prefer `CustomScrollView` with `SliverList` for screens containing both fixed headers and dynamic lists to enable O(visible) performance. Cache streams in `initState` (or use a state management solution) to ensure stability across rebuilds.
