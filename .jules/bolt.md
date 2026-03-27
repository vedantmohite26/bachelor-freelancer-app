
## 2026-02-21 - Consolidated redundant O(N) list iterations in FinanceDashboard
**Learning:** Redundant iterations over a shared data source (like a list of transactions) in multiple sub-widgets can lead to significant UI lag as the data grows. Centralizing these calculations into a single pass in the parent widget's build cycle (using a metrics data class) is a more efficient approach.
**Action:** When building dashboards with multiple summary metrics, prefer a single-pass aggregation pattern over multiple filtered iterations.
