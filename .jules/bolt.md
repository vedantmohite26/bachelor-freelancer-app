## 2026-02-21 - [Profile] Eliminate O(N) list builds in Reviews
**Learning:** `ListView.builder` with `shrinkWrap: true` inside a `SingleChildScrollView` is an anti-pattern in Flutter. It forces the entire list to be built at once, defeating virtualization and leading to O(N) performance.
**Action:** Replace `SingleChildScrollView` + `Column` + `ListView.builder(shrinkWrap: true)` with `CustomScrollView` containing `SliverToBoxAdapter` for fixed content and `SliverList` for dynamic datasets to enable true virtualization.

## 2026-02-21 - [Widget] Repaint Isolation for Async Components
**Learning:** List items with internal `FutureBuilder` or other dynamic content trigger frequent repaints.
**Action:** Use `RepaintBoundary` to isolate these components from the main scroll list, reducing the work required by the engine during scrolling.
