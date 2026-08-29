## 2026-02-21 - Caching Future in StatefulWidget for Chat List Items
**Learning:** Instantiating `Future` inline in `FutureBuilder` inside stateless list item widgets (e.g. `_ChatListItem`) causes `FutureBuilder` to treat every parent stream rebuild as a new future, triggering redundant microtasks and rebuilds.
**Action:** Convert item widgets to `StatefulWidget` and cache the `Future` in state during `initState` and `didUpdateWidget` to maintain smooth stream updates.
