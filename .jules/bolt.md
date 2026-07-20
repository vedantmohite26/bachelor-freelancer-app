## 2026-07-20 - [WalletScreen Transaction List Virtualization]
**Learning:** `shrinkWrap: true` on ListViews disables scroll virtualization, causing all list items to be instantiated and laid out at once, which degrades performance for long lists.
**Action:** Replace `SingleChildScrollView` + `Column` + `ListView(shrinkWrap: true)` with a unified `CustomScrollView` and sliver-based architecture (`SliverList`, `SliverToBoxAdapter`) to enable lazy rendering and improve scroll performance.
