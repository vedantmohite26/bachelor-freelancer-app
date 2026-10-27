## 2026-08-15 - Stream Merging in Dart with StreamController
**Learning:** Using `streamA.asyncExpand((a) => streamB.map(...))` to combine two streams in Dart creates a new subscription to `streamB` every single time `streamA` emits an event. For Firestore streams, this repeatedly destroys and re-creates snapshot listeners on Firestore, resulting in high network overhead and duplicate initial snapshot loads.
**Action:** Combine multi-source streams in Dart by creating a `StreamController` that manages static subscriptions to each source stream in `onListen` and cancels them in `onCancel`.
