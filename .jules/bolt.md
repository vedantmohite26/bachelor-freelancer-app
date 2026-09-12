## 2026-10-24 - List Virtualization in HelperReviewsScreen

**Learning:** Replacing `SingleChildScrollView` + `Column` + `ListView.builder(shrinkWrap: true, physics: NeverScrollableScrollPhysics())` with a `CustomScrollView` containing `SliverToBoxAdapter` and `SliverList` enables true viewport list virtualization in Flutter. With `shrinkWrap: true`, Flutter eager-evaluates all items in memory to calculate total list height, disabling lazy loading.
**Action:** When displaying lists of items inside scrollable screens with header components, always use `CustomScrollView` with slivers (`SliverToBoxAdapter` for non-list header content and `SliverList` or `SliverFillRemaining` for list/placeholder data) to preserve lazy rendering and prevent frame drops.
