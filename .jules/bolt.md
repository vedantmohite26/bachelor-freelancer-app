## 2026-06-25 - Virtualizing Lists with CustomScrollView
**Learning:** Combining `SingleChildScrollView` with `ListView.builder(shrinkWrap: true)` is a major performance anti-pattern in Flutter. It disables virtualization, forcing O(N) build complexity and high memory usage for long lists.
**Action:** Always prefer `CustomScrollView` with `SliverList` or `SliverFixedExtentList` for lists within scrollable pages to maintain virtualization (O(visible)). Wrap non-sliver widgets in `SliverToBoxAdapter`.
