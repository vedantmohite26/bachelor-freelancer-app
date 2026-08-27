## 2026-08-27 - Caching Future in StatefulWidget State for FutureBuilder in List Items
**Learning:** Instantiating a `Future` inside a `FutureBuilder` in a `StatelessWidget` item within a list or stream view re-triggers the async call on every parent rebuild, causing redundant operations and potential UI flicker.
**Action:** Convert list item widgets wrapping `FutureBuilder` into `StatefulWidget`s and cache the `Future` instance in state, updating it only in `initState` or `didUpdateWidget` when relevant parameters change.
