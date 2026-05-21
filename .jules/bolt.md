## 2026-06-21 - Future Caching in Firestore Services

**Learning:** Storing the `Future` object itself in an in-memory cache (e.g., `Map<String, Future<T>>`) is a highly effective way to prevent "cache stampedes" or redundant concurrent Firestore requests. When multiple widgets (like `ReviewCard` in a list) request the same user profile simultaneously, they all wait for the same initial `Future` instead of triggering multiple separate network calls.

**Action:** Always prefer caching the `Future` instead of the resolved data for asynchronous operations that might be triggered concurrently by multiple UI components. Ensure cache invalidation is implemented in all relevant update methods.
