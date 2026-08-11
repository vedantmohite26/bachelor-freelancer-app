# Bolt's Journal

## 2026-11-20 - [UserService Profile Future Caching & Cross-Service Invalidation]
**Learning:** Hardcoded database fetches within recurring UI widgets (like `ReviewCard` inside long lists) trigger severe performance issues and excessive database read usage. Implementing a static in-memory Future-based cache layers completely removes redundant reads and UI flickers. However, to prevent reference sharing and accidental mutation of cached collections, results must be deep-copied recursively before being returned to parallel asynchronous callers.
**Action:** Always implement a static Future-based cache wrapper around frequently requested document reads, chaining deep copying and registering synchronous zone-safe error handlers. Ensure all write operations (including cross-service updates like rating updates in `RatingService`) call `invalidateCache` to keep data perfectly consistent.
