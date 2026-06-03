## 2026-06-03 - [Virtualized Leaderboard List]
**Learning:** The `LeaderboardScreen` used the `shrinkWrap: true` anti-pattern for its ranking list, which disabled virtualization and caused the entire list (up to 50 items) to be built and laid out at once, resulting in O(N) performance.
**Action:** Replaced `SingleChildScrollView` + `Column` + `ListView(shrinkWrap: true)` with `CustomScrollView` + `SliverList` to enable virtualization, improving performance to O(visible). Used `DecoratedSliver` to maintain the container's background and rounded corners without sacrificing efficiency.
