## 2026-04-24 - Enabled Virtualization in HelperReviewsScreen
**Learning:** The `shrinkWrap: true` and `NeverScrollableScrollPhysics` pattern in Flutter disables `ListView` virtualization, causing O(N) build complexity. This is a critical bottleneck for screens displaying dynamic content like reviews.
**Action:** Replace `SingleChildScrollView` + `Column` + `ListView(shrinkWrap: true)` with `CustomScrollView` and `SliverList` to ensure O(visible) build complexity. Use `RepaintBoundary` to isolate complex list items from unnecessary repaints.
