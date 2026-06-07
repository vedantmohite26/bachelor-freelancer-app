# Bolt's Journal ⚡

## 2026-06-25 - Initializing Bolt Journal
**Learning:** Virtualization is key for list performance in Flutter. The `shrinkWrap: true` anti-pattern disables virtualization and should be replaced with `CustomScrollView` and slivers.
**Action:** Replace `SingleChildScrollView` + `Column` + `ListView.builder(shrinkWrap: true)` with `CustomScrollView` in `HelperReviewsScreen`.
