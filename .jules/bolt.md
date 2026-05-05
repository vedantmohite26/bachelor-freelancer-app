# Bolt Performance Journal

## 2026-06-25 - Virtualization and Future Memoization in Ratings
**Learning:** Using `shrinkWrap: true` on `ListView` inside a `SingleChildScrollView` is a common performance anti-pattern in Flutter that disables list virtualization. This forces the framework to build and layout all list items at once, which becomes O(N) where N is the total number of items, leading to severe performance degradation as the list grows. Additionally, calling async services (like Firestore) directly in a `FutureBuilder`'s `future` parameter within a build method causes redundant network requests on every widget rebuild.

**Action:** Always prefer `CustomScrollView` with `SliverList` or `SliverFixedExtentList` for large or dynamic lists to ensure O(visible) rendering. For `FutureBuilder`, always cache the future in a `StatefulWidget`'s `initState` and update it selectively in `didUpdateWidget` to prevent redundant async operations.
