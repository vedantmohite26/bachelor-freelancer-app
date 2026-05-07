## 2026-06-19 - [Performance Optimization in Ratings]
**Learning:** Replacing `SingleChildScrollView` + `Column` + `ListView.builder(shrinkWrap: true)` with `CustomScrollView` + `SliverList` enables virtualization in Flutter, reducing rendering complexity from O(N) to O(visible). Additionally, caching `Future`s in `StatefulWidget` state prevents redundant network requests during rebuilds and scrolling.
**Action:** Always prefer `CustomScrollView` for dynamic lists and cache async data futures in `State` to avoid unnecessary API calls.
