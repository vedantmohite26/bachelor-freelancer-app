## 2026-11-15 - FutureBuilder Inline Invocation Bottleneck
**Learning:** In Flutter screens that use `FutureBuilder`, creating a Future directly in the `future` parameter of `FutureBuilder` inside `build()` re-executes the async/Firestore call every time the widget rebuilds (e.g. parent updates, orientation changes, or theme toggles).
**Action:** Convert the screen or widget to a `StatefulWidget` and initialize the Future in `initState()`, storing it in a state variable to be reused by `FutureBuilder`.
