# Bolt's Journal - Critical Learnings

## 2026-02-21 - Stream instantiation inside `StatelessWidget.build()`
**Learning:** Passing a method call that returns a new `Stream` instance (like `jobService.getApplicationCountStream(...)`) directly into `StreamBuilder`'s `stream` argument inside a `StatelessWidget.build()` causes `StreamBuilder.didUpdateWidget` to detect a new stream object on every parent rebuild or state update. This causes Flutter to unsubscribe and re-subscribe to Firestore listeners repeatedly, causing stream listener churn and unnecessary network traffic.
**Action:** Convert item card components like `_JobCard` to `StatefulWidget`s and cache the `Stream` instance in state, updating it only when the underlying ID changes in `didUpdateWidget` or `didChangeDependencies`.
