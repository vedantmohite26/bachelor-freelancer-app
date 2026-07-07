## 2026-06-25 - Virtualization Bottleneck in Reviews
**Learning:** Found 'shrinkWrap: true' inside 'SingleChildScrollView' in 'HelperReviewsScreen'. This anti-pattern disables Flutter's list virtualization, causing the entire list to be rendered at once, which leads to O(N) layout/paint time and memory usage.
**Action:** Use 'CustomScrollView' with 'SliverList' instead of nested scrollables to restore virtualization and ensure smooth scrolling regardless of list size.
