## 2026-06-20 - Virtualizing Large Lists in Flutter
**Learning:** Using `SingleChildScrollView` with a nested `ListView` (even with `shrinkWrap: true`) disables virtualization, causing O(N) build time and high memory usage.
**Action:** Always prefer `CustomScrollView` with `SliverList` or `SliverFixedExtentList` for large datasets. Use `DecoratedSliver` to apply decorations like rounded backgrounds to a group of slivers.
