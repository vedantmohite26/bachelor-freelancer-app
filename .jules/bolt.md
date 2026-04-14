
## 2026-04-14 - [Fixed shrinkWrap: true in HelperReviewsScreen]
**Learning:** The `shrinkWrap: true` anti-pattern was found in `HelperReviewsScreen`, causing the entire list to be built at once within a `SingleChildScrollView`. This prevents list virtualization and leads to performance degradation as the number of reviews grows.
**Action:** Replace `SingleChildScrollView` + `Column` + `ListView.builder(shrinkWrap: true)` with `CustomScrollView` and `SliverList` to enable proper virtualization. Ensure all children of `CustomScrollView` are slivers (using `SliverToBoxAdapter`, `SliverPadding`, etc.).
