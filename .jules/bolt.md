## 2025-02-21 - Sliver Virtualization for Long Lists
**Learning:** Using `shrinkWrap: true` on a `ListView` inside a `SingleChildScrollView` is a common performance anti-pattern in Flutter that disables UI virtualization. This causes the entire list to be rendered at once, leading to significant memory and build-time overhead for long lists (e.g., reviews, leaderboards).
**Action:** Replace `SingleChildScrollView` + `shrinkWrap: true` with `CustomScrollView` and `SliverList` to enable proper lazy-loading virtualization.

## 2025-02-21 - Centering Placeholders in CustomScrollView
**Learning:** Standard `Center` or `Box` widgets cannot be direct children of `CustomScrollView.slivers`. They must be wrapped in `SliverToBoxAdapter` or `SliverFillRemaining`.
**Action:** Use `SliverFillRemaining(hasScrollBody: false, child: ...)` to properly center loading indicators or empty state messages within a `CustomScrollView` viewport.
