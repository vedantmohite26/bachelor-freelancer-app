## 2026-06-20 - [Virtualized Transaction List in WalletScreen]
**Learning:** The `WalletScreen` used the `shrinkWrap: true` anti-pattern inside a `SingleChildScrollView`. This disables UI virtualization, forcing Flutter to build and layout the entire list of transactions even if only a few are visible. While `WalletService` currently limits to 20 entries, as the app scales or if this limit is increased, it would lead to significant frame drops and high memory usage.

**Action:** Replace `SingleChildScrollView` + `Column` + `ListView.builder(shrinkWrap: true)` with `CustomScrollView` and `SliverList.builder`. This ensures O(visible) rendering performance regardless of the list length. Also, removed a redundant `SizedBox` in the `PageView` which caused an extra empty swipe page.
