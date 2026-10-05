## 2026-02-21 - HomeScreen Stream Caching in Bottom Navigation
**Learning:** Calling `StreamBuilder` with `stream: userService.getUserProfileStream(userId)` inside `build()` recreates a new stream instance on every bottom navigation tab switch (`setState`), causing `StreamBuilder` to cancel the active stream subscription and open a new Firestore listener each time.
**Action:** Cache stream instances in `didChangeDependencies()` checked against user ID state so `StreamBuilder` retains the active subscription across tab transitions.
