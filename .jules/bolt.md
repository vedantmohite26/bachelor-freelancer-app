## 2026-03-26 - Consolidated Dashboard Metrics
**Learning:** The Finance Dashboard was performing ~13+ redundant list iterations per build cycle due to many small helper widgets each doing their own filtering/folding. This is a common pattern in Flutter that can lead to O(N*M) build complexity.
**Action:** Use a single-pass 'Metrics' object to process data once per snapshot and pass it to child widgets instead of raw data lists.
