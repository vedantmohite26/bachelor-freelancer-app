
## 2026-06-25 - Removing shrinkWrap: true for List Virtualization
**Learning:** Using `SingleChildScrollView` + `Column` + `ListView.builder(shrinkWrap: true)` disables virtualization in Flutter, causing O(N) build/layout performance which is a major bottleneck for growing lists.
**Action:** Replace this pattern with `CustomScrollView` + `SliverList` (or `SliverFillRemaining` if a specific container design is needed) to enable O(visible) rendering and significantly reduce UI thread load and memory usage.
