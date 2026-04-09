## 2026-02-21 - [Virtualization Refactor: HelperReviewsScreen]
**Learning:** The `shrinkWrap: true` anti-pattern on `ListView` inside a `SingleChildScrollView` disables UI virtualization, causing Flutter to layout and paint all items in the list, even those off-screen ((N)$ complexity).
**Action:** Always prefer `CustomScrollView` with `SliverList` for long or dynamic lists to ensure (visible)$ performance. Wrapping individual list items in `RepaintBoundary` further optimizes scrolling when items contain dynamic or complex content.
