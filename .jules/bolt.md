## 2026-10-15 - Stream Instance Caching in StreamBuilder
**Learning:** Calling `getPostsStream()` inside `Widget.build()` of `CampusFeedScreen` caused `StreamBuilder` to receive a new stream reference on every parent rebuild, re-subscribing and re-fetching posts from Firestore unnecessarily.
**Action:** Always convert screens with `StreamBuilder` that invoke stream-getter methods directly into `StatefulWidget` and cache the `Stream` reference in `didChangeDependencies()` or `initState()`.
