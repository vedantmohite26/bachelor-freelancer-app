## 2026-06-25 - Virtualization in LeaderboardScreen
**Learning:** Nested list views with `shrinkWrap: true` inside a `SingleChildScrollView` is a common performance anti-pattern in Flutter that disables virtualization, leading to O(N) build time and high memory usage for large lists.
**Action:** Use `CustomScrollView` with `SliverList` and `SliverChildBuilderDelegate` for large or dynamic lists. Use `DecoratedSliver` and `SliverPadding` to maintain container-like styling for sliver lists without sacrificing virtualization performance.
