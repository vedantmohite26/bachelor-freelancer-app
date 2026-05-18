## 2026-06-21 - [UserService Profiling & Optimization]
**Learning:** Redundant Firestore fetches for user profiles (e.g., in `ReviewCard` within lists) create significant network overhead and UI lag. Caching the `Future` of the fetch (instead of just the result) prevents "cache stampedes" where multiple widgets request the same data simultaneously.
**Action:** Use in-memory `Future` caching in Flutter services for frequently accessed, relatively static data like user profiles.
