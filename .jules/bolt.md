## 2026-06-21 - Service-level caching and virtualization
**Learning:** Redundant Firestore fetches for user profiles (N+1 in lists) and rating distributions were causing unnecessary network load and latency. Nested scroll views with `shrinkWrap: true` were disabling virtualization, leading to O(N) build/layout time.
**Action:** Implement `Future` caching in services to share concurrent requests and enable virtualization using `CustomScrollView` + `SliverList` for all long lists.
