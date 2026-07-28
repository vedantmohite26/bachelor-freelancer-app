## 2026-11-20 - Flutter Widget Test pumpAndSettle Timeouts
**Learning:** When writing Flutter widget tests, calling `tester.pumpAndSettle()` will time out if there are infinite animations (like `CircularProgressIndicator`'s rotating spinner) or unfinished network image requests (like network images with `CachedNetworkImage` or standard image loaders).
**Action:** Use repeated `tester.pump()` or a small duration pump (e.g. `tester.pump(const Duration(milliseconds: 100))`) to safely resolve future/stream builders without waiting for infinite loops/animations to finish.
