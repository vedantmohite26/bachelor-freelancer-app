## 2026-06-25 - Service-level In-Memory Future Caching
**Learning:** Storing the `Future` itself in a cache map (e.g., `Map<String, Future<T>>`) is a powerful pattern for request coalescing in Flutter/Dart. It ensures that multiple concurrent callers (like multiple `FutureBuilder`s for the same data) share a single network request instead of spawning redundant ones.
**Action:** Always prefer caching the `Future` rather than the resolved data for asynchronous operations to prevent 'cache stampedes' during initial UI rendering. Ensure proper `.catchError` handling to invalidate the cache if the future fails.

## 2026-06-25 - Cross-Service Cache Invalidation
**Learning:** When one service (e.g., `RatingService`) performs an action that modifies data fetched by another service (e.g., `UserService`), dependencies must be explicitly managed to ensure data consistency.
**Action:** Use `ProxyProvider` in `main.dart` to inject services that require cross-service invalidation, and always call the invalidation method (e.g., `invalidateCache`) after successful data-altering operations.
