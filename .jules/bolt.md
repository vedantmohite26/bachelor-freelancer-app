## 2024-05-22 - [Refactor HelperReviewsScreen to use CustomScrollView]
**Learning:** The `shrinkWrap: true` anti-pattern on `ListView.builder` inside a `SingleChildScrollView` was used for the reviews list. This disables virtualization, forcing Flutter to build and layout every review card, regardless of visibility. As the number of reviews grows, this causes significant performance degradation.
**Action:** Replace `SingleChildScrollView` + `Column` + `ListView.builder(shrinkWrap: true)` with a `CustomScrollView` and `SliverList` to enable virtualization and improve rendering performance from O(N) to O(visible).

## 2024-05-22 - [RepaintBoundary on ReviewCard]
**Learning:** `ReviewCard` contains a `FutureBuilder` for user profiles. When this future completes or when the list scrolls, it can trigger expensive repaints of the entire card or even the whole list.
**Action:** Wrap complex list items like `ReviewCard` in a `RepaintBoundary` to isolate their repaint layer, reducing the overall workload on the Flutter engine during scrolling and dynamic updates.
