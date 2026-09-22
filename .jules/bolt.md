## 2026-08-15 - Consolidate Redundant List Traversals in Financial Dashboard

**Learning:** `FinanceDashboardScreen` previously iterated over the transaction list ~14 separate times using `.where` and `.fold` across its sub-widgets during every build. Consolidating these computations into a single $O(N)$ pass (`_calculateMetrics`) drastically reduces redundant CPU cycles and garbage collection overhead during UI updates.
**Action:** When rendering multi-chart dashboard screens that present different views/aggregations of a single dataset, compute a single metrics data object in $O(N)$ time before building individual sub-widgets instead of letting each widget re-traverse the raw dataset.
