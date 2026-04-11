## 2026-04-18 - [Sliver Virtualization for Performance]
**Learning:** The `shrinkWrap: true` + `NeverScrollableScrollPhysics` pattern in Flutter is a significant performance bottleneck that forces O(N) layout and builds, disabling virtualization even for small lists.
**Action:** Always prefer `CustomScrollView` with `SliverList` or `SliverFixedExtentList` for screens containing lists to ensure O(visible) performance and better memory efficiency.

## 2026-04-18 - [State Management in Slivers]
**Learning:** Using `Consumer` or `StreamBuilder` within `CustomScrollView`'s `slivers` list is highly effective for granular updates, provided they return sliver-compatible widgets (e.g., `SliverList`, `SliverToBoxAdapter`).
**Action:** Ensure builders in a sliver context always return slivers to avoid layout crashes. Use `SliverPadding` for consistent spacing within the sliver hierarchy.
