## 2026-06-25 - List Virtualization in LeaderboardScreen
**Learning:** Nested scroll views using `shrinkWrap: true` inside a `SingleChildScrollView` (or similar) disable list virtualization, causing Flutter to render all items at once. This significantly impacts performance as the list grows.
**Action:** Replace `SingleChildScrollView` + `Column` + `ListView` with a `CustomScrollView` and slivers (`SliverList.builder`, `SliverToBoxAdapter`). Use `DecoratedSliver` for area decorations.

## 2026-06-25 - Redundant Provider Lookups in Builders
**Learning:** Performing `Provider.of<T>(context)` lookups inside an `itemBuilder` of a long list can be expensive (O(depth-of-tree) per item).
**Action:** Lift the provider lookup outside the builder and pass the value (or store it in a variable) to the builder to reduce CPU overhead during scrolling.
