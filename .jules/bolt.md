# Bolt ⚡ Performance Journal

## 2026-06-12 - Virtualization of WalletScreen Transactions
**Learning:** Using `SingleChildScrollView` + `Column` + `ListView.builder(shrinkWrap: true)` is a performance anti-pattern in Flutter. It disables virtualization, forcing the app to layout and build all items in the list even if they are not visible. This leads to O(N) build complexity and high memory usage.
**Action:** Always prefer `CustomScrollView` with `SliverList` or `SliverFixedExtentList` for large or dynamic lists. This enables virtualization, reducing build complexity to O(visible).

## 2026-06-12 - Rebuild Scope Optimization in Flutter
**Learning:** Using `context.watch<T>()` at the top of a `build` method causes the entire widget to rebuild whenever *any* part of the provided object changes.
**Action:** Use `context.select<T, R>((value) => ...)` to only rebuild the widget when the specific properties it depends on change. This minimizes unnecessary repaints and builds.
