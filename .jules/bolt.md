## 2026-06-18 - Virtualization of Leaderboard with Slivers
**Learning:** Using `SingleChildScrollView` + `Column` + `ListView.builder(shrinkWrap: true)` disables UI virtualization, leading to O(N) build and layout time. This is particularly problematic for large lists like leaderboards or reviews.
**Action:** Replace nested scrollable widgets with a single `CustomScrollView` and use `SliverList` or `SliverGrid` for large datasets. Use `DecoratedSliver` to maintain background styling for sliver lists.
