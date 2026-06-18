## 2026-06-18 - Nested Scroll Virtualization
**Learning:** Using `shrinkWrap: true` on `ListView` inside a `SingleChildScrollView` disables virtualization, causing O(N) rendering where N is the total number of items. This can lead to significant jank as the list grows.
**Action:** Use `CustomScrollView` with `SliverList` and `SliverToBoxAdapter` to maintain O(visible) performance and enable virtualization for dynamic lists.

## 2026-06-18 - Sliver Conditional Rendering
**Learning:** When using `StreamBuilder` with `CustomScrollView`, returning the `CustomScrollView` from the builder (or wrapping it) allows for conditional rendering of slivers (like `SliverFillRemaining` for empty/loading states) while keeping the overall scroll experience unified.
**Action:** Wrap the `CustomScrollView` in the `StreamBuilder` and use `SliverFillRemaining` with `hasScrollBody: false` for full-viewport placeholder content.
