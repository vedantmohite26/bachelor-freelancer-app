## 2026-04-18 - [WalletScreen List Virtualization]
**Learning:** Found the `shrinkWrap: true` anti-pattern in `WalletScreen`, where a `ListView.builder` was nested inside a `SingleChildScrollView`. This disables list virtualization, causing Flutter to build and layout all list items at once, leading to $O(N)$ performance issues as the transaction history grows.
**Action:** Use `CustomScrollView` with `SliverList` or `SliverList.builder` to enable virtualization and achieve $O(Visible)$ performance for long lists.
