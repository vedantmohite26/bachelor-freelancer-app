# Bolt's Journal - Critical Learnings

## 2026-11-20 - Caching Firestore Streams in StatefulWidget state
**Learning:** Re-invoking Firestore stream getters inside a Flutter `Widget.build()` method causes `StreamBuilder` to cancel and recreate its underlying `StreamSubscription` on every parent rebuild. Caching the `Stream` instance in `initState()` prevents subscription thrashing and redundant network/database controller churn.
**Action:** Always convert stream-listening screens/components to `StatefulWidget` and cache the `Stream` in `initState()` using `listen: false` when referencing `Provider`.
