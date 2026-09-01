# Bolt's Journal

## 2026-11-01 - Caching `FutureBuilder` futures in `_ChatListItem` state
**Learning:** In Flutter lists rendering dynamic cards (such as chat list items), instantiating asynchronous futures directly inside `FutureBuilder.future` during `itemBuilder` execution causes `FutureBuilder` to re-trigger the asynchronous call on every parent rebuild or scroll frame. Converting item cards to `StatefulWidget` and caching the `Future` in `initState` prevents redundant async invocations and reduces cache hit check overhead during scrolling.
**Action:** When using `FutureBuilder` within list items (e.g. `ListView.separated` or `SliverList`), convert the list item to a `StatefulWidget` and initialize the future in `initState()` (or `didUpdateWidget()`) to preserve the cached `Future` instance across rebuilds.
