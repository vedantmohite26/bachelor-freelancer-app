# Bolt's Performance Journal

## 2024-05-22 - UI Virtualization vs. ShrinkWrap Anti-Pattern
**Learning:** Using `SingleChildScrollView` + `ListView.builder(shrinkWrap: true)` is a major performance anti-pattern in Flutter. It forces the entire list to be laid out at once (O(N)), losing all benefits of lazy loading/virtualization. This is especially damaging when list items (like `ReviewCard`) contain `FutureBuilder` or `StreamBuilder`, as it triggers all asynchronous calls simultaneously upon screen entry.
**Action:** Replace `SingleChildScrollView` + `shrinkWrap` with `CustomScrollView` and `SliverList`. This ensures only visible items are built and their associated side effects (like API calls) are deferred until they scroll into view (O(visible)).
