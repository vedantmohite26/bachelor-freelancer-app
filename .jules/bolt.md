## 2026-06-15 - [Virtualization for long lists]
**Learning:** Combining `SingleChildScrollView` with `ListView.builder(shrinkWrap: true)` disables virtualization in Flutter, leading to O(N) layout and build performance. This is a significant bottleneck as data sets grow.
**Action:** Use `CustomScrollView` with `SliverList` or `SliverFixedExtentList` to enable lazy loading (virtualization), reducing cost to O(visible).

## 2026-06-15 - [Stream caching in widgets]
**Learning:** Initializing streams directly in the `build` method or within `StreamBuilder`'s parameter can lead to redundant subscriptions and unnecessary Firestore reads on every rebuild.
**Action:** Convert widgets to `StatefulWidget` and initialize the stream in `initState`. Use `didUpdateWidget` to refresh the stream only when critical parameters (like IDs) change.
