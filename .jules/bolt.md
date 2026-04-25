## 2026-06-25 - [Flutter Virtualization Crash]
**Learning:** Placing a `StreamBuilder` or any non-sliver widget directly into the `slivers` list of a `CustomScrollView` causes a runtime crash. `CustomScrollView` expects only `RenderSliver` children.
**Action:** Always wrap `CustomScrollView` with the `StreamBuilder`, or ensure the builder returns only sliver-compatible widgets (e.g., `SliverList`, `SliverToBoxAdapter`) when used within the `slivers` list.

## 2026-06-25 - [shrinkWrap: true Anti-pattern]
**Learning:** `ListView.builder(shrinkWrap: true)` inside a `SingleChildScrollView` disables virtualization and forces the entire list to be rendered at once ($O(N)$).
**Action:** Replace with `CustomScrollView` + `SliverList` to enable virtualization ($O(\text{visible items})$) for better performance and memory efficiency.
