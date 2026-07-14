## 2026-02-21 - Virtualizing Nested Lists for Performance
**Learning:** Using `shrinkWrap: true` on a `ListView` inside a `SingleChildScrollView` is a common performance anti-pattern in Flutter. It disables virtualization by forcing the list to calculate the dimensions of all children immediately, leading to O(n) layout and build times.
**Action:** Always prefer `CustomScrollView` with `SliverList` or `SliverFixedExtentList` for screens with headers followed by long lists. Use `SliverToBoxAdapter` for the headers and `SliverPadding` for list margins to maintain virtualization.
