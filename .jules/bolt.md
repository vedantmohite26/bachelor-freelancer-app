## 2026-06-15 - Flutter List Virtualization: Beyond shrinkWrap

**Learning:** Combining `SingleChildScrollView` with `ListView.builder(shrinkWrap: true)` is a major performance anti-pattern in Flutter. `shrinkWrap: true` forces the list to calculate the dimensions of all children immediately, defeating virtualization and leading to O(N) build/layout time.

**Action:** Always prefer `CustomScrollView` with `SliverList` for large or dynamic lists. Use `SliverToBoxAdapter` for fixed headers/footers and `SliverFillRemaining(hasScrollBody: false)` for centered placeholders (loading/empty states). This ensures O(visible) performance.
