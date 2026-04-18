
## 2026-02-21 - [WalletScreen List Virtualization]
**Learning:** The `shrinkWrap: true` and `NeverScrollableScrollPhysics()` pattern inside a `SingleChildScrollView` is a major performance bottleneck as it forces the entire list to be built at once, losing virtualization benefits (O(N) vs O(visible)).
**Action:** Always prefer `CustomScrollView` with `SliverList` for dynamic lists within scrollable pages to maintain O(visible) performance. Use `SliverToBoxAdapter` for headers and `SliverFillRemaining(hasScrollBody: false)` for centered empty states.
