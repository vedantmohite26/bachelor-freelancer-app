## 2026-06-25 - [Future Caching & Shared State Safety]
**Learning:** In Flutter services, caching `Future` objects is an efficient way to handle concurrent asynchronous requests (e.g., from multiple `FutureBuilder`s) without redundant network calls. However, returning the raw cached `Map` or `Object` can lead to unintended shared state mutations if one caller modifies the result.
**Action:** Always return a copy of the cached data (e.g., `Map<String, dynamic>.from(data)`) when providing cached results to different parts of the application to ensure isolation and data integrity.
