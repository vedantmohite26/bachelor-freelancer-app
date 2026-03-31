## 2025-03-24 - Flutter Scroll Performance: `shrinkWrap: true` Anti-pattern
**Learning:** Using `SingleChildScrollView` with a nested `ListView` and `shrinkWrap: true` is a major performance bottleneck in Flutter. It forces the entire list to be laid out and painted upfront, disabling the benefits of lazy loading and viewport-based rendering.
**Action:** Always prefer `CustomScrollView` with `Slivers` (e.g., `SliverList`, `SliverGrid`) when building complex scrollable screens with dynamic lists. This ensures efficient memory usage and smooth 60/120 FPS scrolling even with large datasets.
