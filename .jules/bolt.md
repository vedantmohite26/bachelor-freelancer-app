# Bolt's Journal

## 2026-06-25 - In-memory cache in UserService
**Learning:** Found that `UserService.getUserProfile` does not cache profiles, leading to redundant Firestore requests when rendering items like `ReviewCard` inside long lists.
**Action:** Implement static in-memory Future-based caching in `UserService` to allow parallel, concurrent calls to share the same asynchronous request.
