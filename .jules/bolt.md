## 2026-06-20 - [Caching Futures in FutureBuilder]
**Learning:** Creating a new Future instance directly within the `future` property of a `FutureBuilder` in a `StatelessWidget`'s `build` method triggers the async operation (e.g., Firestore query) on every rebuild. This leads to redundant network calls and increased costs.
**Action:** Convert the component to a `StatefulWidget` and initialize the Future in `initState`. Use `didUpdateWidget` to refresh the Future only when dependencies (like `userId`) change.
