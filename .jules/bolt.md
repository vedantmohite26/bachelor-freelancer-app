## 2026-06-19 - Virtualization in HelperReviewsScreen
**Learning:** Using `SingleChildScrollView` with an inner `ListView.builder(shrinkWrap: true)` is a performance anti-pattern that disables virtualization. All items in the list are built and laid out at once, which becomes a bottleneck (O(N)) as data grows.
**Action:** Replace `SingleChildScrollView` + `Column` with `CustomScrollView`. Wrap non-list elements in `SliverToBoxAdapter` and convert the `ListView.builder` to `SliverList` to enable virtualization (O(visible items)).

## 2026-06-19 - Efficient Stream Management in StatefulWidgets
**Learning:** Creating a stream directly in a `StreamBuilder`'s `stream` property inside a `build` method causes the stream to be recreated on every rebuild, leading to redundant subscriptions and potential UI flickering.
**Action:** Convert the widget to a `StatefulWidget`, initialize the stream in `initState`, and update it in `didUpdateWidget` only when relevant parameters (like `helperId`) change.
