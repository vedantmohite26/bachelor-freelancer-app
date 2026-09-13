
## 2026-11-20 - Cache Future in StatefulWidget for List Items
**Learning:** Instantiating `FutureBuilder(future: userService.getUserProfile(...))` directly in `build()` of list items causes the Future to re-execute every time the list or parent updates or scrolls. Converting the item to a `StatefulWidget` and caching the Future in `initState` and `didUpdateWidget` prevents redundant async database calls and expensive re-renders.
**Action:** When `FutureBuilder` is used inside repeating list items or child components subject to rebuilds, always cache the `Future` in component state (`initState`/`didUpdateWidget`).
