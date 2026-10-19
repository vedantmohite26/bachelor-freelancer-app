## 2026-03-31 - Leaderboard List Virtualization via CustomScrollView
**Learning:** Combining `SingleChildScrollView` with `ListView.builder(shrinkWrap: true)` causes double layout passes and forces Flutter to instantiate all list items simultaneously, disabling viewport virtualization.
**Action:** Replace nested scroll views with `CustomScrollView` using `SliverToBoxAdapter` for top elements and `DecoratedSliver` + `SliverPadding` + `SliverList.builder` for virtualized lists.
