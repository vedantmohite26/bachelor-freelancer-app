# Bolt's Performance Journal

## 2025-05-22 - Identifying the `shrinkWrap: true` Anti-Pattern
**Learning:** The use of `SingleChildScrollView` combined with `ListView.builder(shrinkWrap: true)` is a common anti-pattern in this codebase. It forces the `ListView` to build all its children at once to determine its height, which destroys virtualization benefits and leads to O(N) build time and memory usage. This is particularly problematic for lists like the Leaderboard which can have up to 50 items.
**Action:** Replace this pattern with `CustomScrollView` and `SliverList` to enable proper lazy loading and reduce initial build/frame times.
