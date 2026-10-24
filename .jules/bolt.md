
## 2026-08-28 - UserService In-Memory Profile Caching & Deep Copy Isolation
**Learning:** Frequent UI re-renders and repeated calls to `getUserProfile` across screens trigger redundant Firestore document reads, increasing network latency and read costs. Caching inflight and resolved futures in `UserService` eliminates redundant requests. Chaining `.then((data) => data != null ? _deepCopyMap(data) : null)` on cached profile futures prevents concurrent callers from sharing and mutating nested maps by reference.
**Action:** Always wrap cached asynchronous profile map objects with deep-copy isolation before returning them to callers, and ensure write methods invalidate cached user entries.
