## 2026-11-20 - Caching Futures in Stateful Card Widgets
**Learning:** Re-instantiating `Future` calls (such as `userService.getUserProfile(id)`) directly inside a `FutureBuilder`'s `build` method in Flutter widgets causes repeated asynchronous fetches, UI flicker, and redundant CPU overhead on parent rebuilds.
**Action:** Convert item/card widgets in lists that use `FutureBuilder` to `StatefulWidget` and initialize/cache the `Future` in `initState()`.
