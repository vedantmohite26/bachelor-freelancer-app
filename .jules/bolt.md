
## 2025-02-21 - [Consolidated Redundant List Iterations in FinanceDashboard]
**Learning:** In complex dashboards (like FinanceDashboardScreen), multiple helper widgets often filter and aggregate the same data set (e.g., a list of transactions) independently. This leads to redundant (N)$ iterations (in this case, ~14 passes) in every build cycle.
**Action:** Consolidate multiple independent , , and  operations on the same collection into a single-pass calculation class (e.g., `_DashboardMetrics`) instantiated once per build (within the StreamBuilder/FutureBuilder).

## 2025-02-21 - [Consolidated Redundant List Iterations in FinanceDashboard]
**Learning:** In complex dashboards (like FinanceDashboardScreen), multiple helper widgets often filter and aggregate the same data set (e.g., a list of transactions) independently. This leads to redundant O(N) iterations (in this case, ~14 passes) in every build cycle.
**Action:** Consolidate multiple independent 'where', 'fold', and 'map' operations on the same collection into a single-pass calculation class (e.g., _DashboardMetrics) instantiated once per build (within the StreamBuilder/FutureBuilder).
