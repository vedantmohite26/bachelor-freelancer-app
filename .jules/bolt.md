# Bolt's Performance Journal ⚡

## 2026-06-21 - Optimizing Ratings UI Performance

**Learning:** Redundant Firestore fetches in `RatingSummaryCard` and lack of list virtualization in `HelperReviewsScreen` are impacting performance and costs. `RatingSummaryCard` as a `StatelessWidget` triggers a new `FutureBuilder` fetch on every rebuild. `HelperReviewsScreen` using `SingleChildScrollView` + `ListView(shrinkWrap: true)` loads all reviews at once, which is O(N) instead of O(visible).

**Action:**
1. Convert `RatingSummaryCard` to `StatefulWidget` and cache the `Future`.
2. Refactor `HelperReviewsScreen` to use `CustomScrollView` and `SliverList` for virtualization.
