## 2026-08-07 - Consolidating UI build calculations into single pass
**Learning:** Iterating through transaction lists ~14 times via multiple `.where()` and `.fold()` calls inside the Flutter widget `build` method creates redundant O(N) traversals, leading to high CPU/memory utilization as lists grow.
**Action:** Consolidate multiple filter/fold list operations into a single-pass `_calculateMetrics` method that iterates through the list exactly once and returns a metrics data structure.
