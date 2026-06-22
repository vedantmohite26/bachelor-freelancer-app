## 2026-06-15 - Virtualize Leaderboard List
**Learning:** Using `SingleChildScrollView` + `ListView(shrinkWrap: true)` is an anti-pattern in Flutter that disables virtualization, leading to O(N) build time and memory usage. For lists that can grow large, such as a leaderboard, this is a significant performance bottleneck.
**Action:** Use `CustomScrollView` with `SliverList` and `SliverToBoxAdapter` to enable lazy loading. Use `DecoratedSliver` and `SliverPadding` to maintain container-like styling without breaking the sliver protocol.
