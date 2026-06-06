
## 2026-06-06 - Virtualized Review List in HelperReviewsScreen
**Learning:** Using `shrinkWrap: true` inside a `SingleChildScrollView` for lists is a common performance anti-pattern in Flutter that disables virtualization.
**Action:** Replace `SingleChildScrollView` + `Column` + `ListView(shrinkWrap: true)` with `CustomScrollView` and `SliverList` to maintain O(visible) rendering efficiency.
