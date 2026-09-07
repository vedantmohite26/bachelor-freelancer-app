## 2026-02-21 - Consolidated Job Feed Location and Distance Processing
**Learning:** In `JobFeedScreen`, calculating location distances (`Geolocator.distanceBetween`) and formatting distance strings inside `ListView.separated`'s `itemBuilder` caused redundant trigonometric calculations on every scroll event and item rebuild.
**Action:** Consolidate distance calculation and filtering into a single pass per stream update in `StreamBuilder`, attaching `_distanceDisplay` directly to the job map before rendering.
