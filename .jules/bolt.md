## 2026-04-24 - Optimized HelperReviewsScreen with virtualization
**Learning:** Using `ListView.builder` with `shrinkWrap: true` inside a `SingleChildScrollView` is a common performance anti-pattern in Flutter. It disables list virtualization, causing O(N) build time and high memory usage for long lists.
**Action:** Replace `SingleChildScrollView` + `Column` + `ListView.builder(shrinkWrap: true)` with `CustomScrollView` and `SliverList` to enable virtualization (O(visible)). Use `SliverToBoxAdapter` for static components and `SliverFillRemaining` for centered placeholder states.
