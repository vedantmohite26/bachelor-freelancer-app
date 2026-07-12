## 2026-07-12 - Virtualization with DecoratedSliver
**Learning:** Using `shrinkWrap: true` on a `ListView` nested within a `SingleChildScrollView` disables virtualization in Flutter, causing all items to be built at once. This is a significant performance bottleneck for long lists.
**Action:** Replace `SingleChildScrollView` + `ListView(shrinkWrap: true)` with a `CustomScrollView` and `SliverList.builder`. Use `DecoratedSliver` to maintain visual consistency (like background containers with rounded corners) while keeping the benefits of virtualization.

## 2026-07-12 - Redundant Provider Lookups in Builders
**Learning:** Performing `Provider.of<T>(context)` lookups inside an `itemBuilder` of a long list can lead to significant overhead as it's executed for every item on every rebuild/scroll.
**Action:** Fetch required data from Providers once outside the builder (or before the `CustomScrollView`) and pass the values directly to the item widgets.
