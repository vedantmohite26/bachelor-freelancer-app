## 2025-02-23 - Lazy Loading with SliverList

**Learning:** Using `SingleChildScrollView` + `Column` + `ListView.builder(shrinkWrap: true)` is a performance anti-pattern in Flutter. It forces the `ListView` to calculate and render all items upfront, negating the benefits of virtualization. For screens with potentially long lists (like reviews), this leads to $O(N)$ build time and memory usage.

**Action:** Replace this pattern with `CustomScrollView` and `SliverList`. Wrap static content in `SliverToBoxAdapter` and use `SliverPadding` with `SliverList` for lazy loading. This reduces initial build time and memory footprint to $O(\text{visible items})$.
