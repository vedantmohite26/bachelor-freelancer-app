## 2026-06-25 - Caching Futures in StatefulWidget

**Learning:** Creating a `Future` directly in the `build` method of a `StatelessWidget` (via `FutureBuilder`) causes redundant asynchronous calls (e.g., Firestore fetches) every time the widget rebuilds. This is a common performance pitfall in Flutter.

**Action:** Convert such widgets to `StatefulWidget` and cache the `Future` in `initState`. Use `didUpdateWidget` to refresh the future only when relevant input parameters change. This ensures asynchronous operations are only triggered when necessary.
