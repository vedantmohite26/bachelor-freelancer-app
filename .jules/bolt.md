# Bolt's Performance Journal - Critical Learnings Only

## 2024-05-22 - [Refactor shrinkWrap in HelperReviewsScreen]
**Learning:** The use of `shrinkWrap: true` in `ListView` inside a `SingleChildScrollView` is a known performance anti-pattern in Flutter as it forces the list to calculate the dimensions of all its children upfront, defeating lazy loading.
**Action:** Replace `SingleChildScrollView` + `Column` + `ListView(shrinkWrap: true)` with `CustomScrollView` + `SliverList` (or `SliverToBoxAdapter`) to enable proper virtualization.
