## 2026-06-15 - Service-level Future Caching
**Learning:** In a Firestore-backed Flutter app, widgets like `ReviewCard` often trigger redundant reads for the same user profile. Storing the `Future` in a service-level Map (collapsing requests) is more efficient than just caching the result, as it handles concurrent requests from multiple widgets and prevents "cache stampedes".
**Action:** Use `Map<String, Future<T>>` for asynchronous service-level caching to ensure only one network request is made even if multiple components request the same data simultaneously.
