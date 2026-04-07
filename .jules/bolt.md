## 2024-05-22 - Optimized HelperReviewsScreen virtualization

**Learning:** Using `SingleChildScrollView` + `ListView.builder(shrinkWrap: true)` is an anti-pattern in Flutter that forces the entire list to be built at once, defeating virtualization. In `HelperReviewsScreen`, this was particularly problematic as each `ReviewCard` contains a `FutureBuilder` to fetch reviewer profiles. Without virtualization, *all* profile fetches were triggered simultaneously on screen entry.

**Action:** Replace `SingleChildScrollView` + `Column` + `ListView` with `CustomScrollView` and `SliverList`. Wrap the `CustomScrollView` in `StreamBuilder` to ensure only sliver-compatible widgets (like `SliverList` or `SliverToBoxAdapter`) are returned within the `slivers` list. This enables lazy-loading of both the UI components and the associated data fetches (like reviewer profiles).
