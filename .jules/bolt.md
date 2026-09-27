## 2026-11-23 - Caching Firestore Streams in Home Dashboard Tabs
**Learning:** Instantiating Firestore streams inline within `StreamBuilder.stream` inside `build()` causes `StreamBuilder` to tear down and recreate Firestore listeners on every widget rebuild or state change (e.g., when opening modals, toggling online status, or scrolling).
**Action:** Always cache stream instances in `didChangeDependencies` (tracked per user ID where applicable) and pass the cached stream reference to `StreamBuilder`. Wrap list items in `RepaintBoundary` to isolate repaints.
