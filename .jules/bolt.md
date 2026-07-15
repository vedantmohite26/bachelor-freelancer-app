## 2026-07-15 - Optimized User Profile Fetching with Future Caching
**Learning:** Implementing in-memory caching of the `Future` itself (instead of just the result) prevents redundant concurrent Firestore reads for the same document (request collapsing). Deep copying returned data with `Map.from()` prevents UI components from accidentally mutating shared cache state.
**Action:** Use Future-based caching in services where multiple UI components might request the same data simultaneously (e.g., user profiles in list items).
