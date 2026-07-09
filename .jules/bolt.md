## 2026-06-15 - Optimizing Leaderboard Virtualization
**Learning:** Using `ListView` with `shrinkWrap: true` inside a `SingleChildScrollView` is a major performance anti-pattern in Flutter as it disables virtualization. For complex layouts with mixed static and dynamic content, `CustomScrollView` with slivers is the correct approach to maintain performance.
**Action:** Always check for `shrinkWrap: true` in long lists and refactor to `CustomScrollView` using `SliverList` or `SliverGrid` to enable virtualization.
