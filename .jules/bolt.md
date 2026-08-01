# Bolt's Journal

## 2026-11-20 - In-Memory Asynchronous Future Caching in UserService
**Learning:** Storing futures rather than resolved values in a service cache completely prevents redundant, simultaneous backend/database fetches by sharing the exact same future object among parallel callers. Adding deep copies prevents shared state mutation. Syncing the cache with real-time Firestore stream snapshots is an extremely effective way to maintain data freshness.
**Action:** When building service-level caches in client-side apps, cache the `Future` directly, return deep copies, and synchronize stream snapshots with the future cache to maintain full data consistency across streams and future builders.
