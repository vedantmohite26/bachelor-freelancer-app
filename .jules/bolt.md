## 2025-05-15 - Redundant List Iterations in Dashboard
**Learning:** The `FinanceDashboardScreen` performed 13 separate $O(N)$ iterations over the transaction list to calculate various metrics during every build. This is a significant bottleneck as the transaction history grows.
**Action:** Consolidate multiple calculations into a single-pass loop using a dedicated metrics container class to achieve $O(N)$ instead of $O(M \times N)$ complexity.
