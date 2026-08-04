## 2026-10-24 - [In-Memory Future Caching with Recursive Deep Copying]
**Learning:** Returning cached maps/lists directly in Dart allows concurrent or subsequent callers to mutate the internal cache by reference, leading to silent consistency bugs. Merely doing `Map.from(data)` only does a shallow copy, leaving nested lists/maps shared by reference. A true recursive deep copy helper is required for absolute consistency.
**Action:** Always implement recursive deep-copying (`_deepCopyMap` / `_deepCopyList`) when returning cached collections from service-level in-memory caches.

## 2026-10-24 - [Synchronous Zone Error Handling in Futures Cache]
**Learning:** In service-level asynchronous caches storing `Future` values, failed futures must be evicted from the cache immediately upon failure to prevent subsequent reads from encountering permanent stale errors. Additionally, registering `.catchError` immediately upon future instantiation ensures zone exceptions are properly caught, avoiding unhandled Zone crashes.
**Action:** Synchronously register a `.catchError` block on the cached `Future` immediately upon instantiation, which calls `invalidateCache` and rethrows the error.
