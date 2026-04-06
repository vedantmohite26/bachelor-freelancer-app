## 2024-05-22 - Replacing `shrinkWrap: true` with `SliverList`
**Learning:** The `shrinkWrap: true` anti-pattern with `ListView` inside `SingleChildScrollView` forces the entire list to render at once, killing virtualization. This leads to performance degradation (O(N) layout) as datasets like transaction history grow.
**Action:** Use `CustomScrollView` and `SliverList` for lists within scrollable pages to enable lazy loading (O(visible) layout) and improve UI responsiveness.
