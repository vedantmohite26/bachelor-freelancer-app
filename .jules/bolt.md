## 2026-09-25 - Caching Stream Subscriptions in List Item Widgets
**Learning:** Instantiating `Stream` objects inside `build()` or `StreamBuilder.stream` directly in item cards causes `StreamBuilder` to cancel and re-subscribe to Firestore on every parent rebuild or list filter change.
**Action:** Convert list item cards with streams to `StatefulWidget`s and cache the `Stream` instance in state, updating it only when identifying widget arguments (e.g. `jobId`) change.
