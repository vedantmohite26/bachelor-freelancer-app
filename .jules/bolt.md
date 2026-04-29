# Bolt Performance Journal

## 2026-06-25 - Virtualized WalletScreen Transactions
**Learning:** The `shrinkWrap: true` and `NeverScrollableScrollPhysics()` pattern in Flutter is a performance anti-pattern that disables list virtualization. It causes the entire list to be built at once (O(N)), which is highly inefficient for dynamic data like transaction histories.
**Action:** Use `CustomScrollView` with `SliverList` and `SliverToBoxAdapter` to achieve virtualization. This ensures that only visible items are built (O(visible)), significantly reducing memory usage and frame drops during scrolling.
